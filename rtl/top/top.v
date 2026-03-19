module top #(
    parameter D_WIDTH      = 8,
    parameter BATCH_NUM    = 98,
    parameter ADDR_WIDTH   = 7,
    parameter I_WIDTH      = 18,
    parameter V_WIDTH      = 19,
    parameter THRESHOLD    = 800,
    parameter LEAK_SHIFT   = 3,
    parameter REF_PERIOD   = 3,
    parameter T_WIDTH      = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_loading,
    input  wire [6:0]  addr_in,     // SRAM 位址輸入
    input  wire [15:0] data_in,     // 16-bit 多工輸入 (權重/像素 共用)
    output wire        spike_out,
    output wire        busy,
    output wire        finish
);

    //FSM 狀態定義
    localparam ST_IDLE      = 3'd0;
    localparam ST_LOAD      = 3'd1;
    localparam ST_INTEGRATE = 3'd2; 
    localparam ST_CHECK     = 3'd3; 
    localparam ST_UPDATE    = 3'd4; 
    localparam ST_FINISH    = 3'd5; 

    reg [2:0]  current_mode;
    reg [6:0]  load_counter; 
    reg [1:0]  data_cnt;     
    reg [63:0] pixel_data_in;
    reg        is_initialized; 

    reg        start;
    reg        accumulate_en;
    reg        pixel_valid_in; 

    wire [63:0] rd_weight;      
    wire [6:0]  cur_batch_cnt;         
    wire        rd_valid;     
    
    wire [7:0]  spike_data_out;         
    wire        spike_valid_out;         
    wire [D_WIDTH*T_WIDTH-1:0] trace_data_out; 
    
    wire [63:0] post_trace_8x;    
    
    wire [63:0] weight_new;  
    wire [7:0]  write_en;       
    
    wire        wr_en;
    wire [7:0]  wr_mask;
    wire [63:0] wr_weight;
    wire [6:0]  wr_row;
    wire        l1_done_wire;
    wire [783:0] L2_input_vector;
    
    reg [3:0] check_wait_cnt;
    // 第二階段專用暫存器
    reg [6:0] update_addr;
    reg [1:0] upd_cnt; // 4-Cycle 狀態計數器
    reg       post_spike_latched;

    wire any_stdp_write = |write_en;
    
    assign finish = (current_mode == ST_FINISH);
    assign busy   = (current_mode != ST_IDLE);

    // =======================================================
    // FSM 與 核心控制邏輯
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode   <= ST_IDLE;
            load_counter   <= 7'd0;
            is_initialized <= 1'b0;
            start          <= 1'b0;
            accumulate_en  <= 1'b0;
        end else begin
            start <= 1'b0;
            case (current_mode)
                ST_IDLE: begin
                    if (start_loading) begin
                        if (!is_initialized) begin
                            current_mode <= ST_LOAD;
                            start <= 1'b1;
                            accumulate_en <= 1'b0;
                            load_counter <= 7'd0; 
                        end else begin
                            current_mode <= ST_INTEGRATE;
                            start <= 1'b1;
                            accumulate_en <= 1'b1;
                        end
                    end
                end
                ST_LOAD: begin
                    if (data_cnt == 2'd3) begin
                        load_counter <= load_counter + 1'b1;
                    end
                    // 確保最後一筆資料完整寫入後再跳轉
                    if (load_counter == BATCH_NUM && data_cnt == 2'd0) begin
                        current_mode   <= ST_IDLE; 
                        is_initialized <= 1'b1;
                        load_counter   <= 7'd0;
                    end
                end
                ST_INTEGRATE: begin
                        if (l1_done_wire) begin 
                            current_mode <= ST_CHECK;
                            check_wait_cnt <= 4'd0; // 重置計數器
                        end
                    end
                ST_CHECK: begin
                    // 等待 5 個 Cycle，確保 Layer 2 的 post_spike 已經順利產生並被 latch
                    if (check_wait_cnt == 4'd5) begin
                        current_mode  <= ST_UPDATE;
                        accumulate_en <= 1'b0; 
                    end else begin
                        check_wait_cnt <= check_wait_cnt + 1'b1;
                    end
                end
                ST_UPDATE: begin
                    // 等待最後一個寫入週期完成後結束
                    if (update_addr == BATCH_NUM && upd_cnt == 2'd1) 
                        current_mode <= ST_FINISH;
                end
                ST_FINISH: begin
                    current_mode <= ST_IDLE;
                end
                default: current_mode <= ST_IDLE;
            endcase
        end
    end

    // 發火狀態鎖存 (Global Latch)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) post_spike_latched <= 1'b0;
        else if (current_mode == ST_IDLE || current_mode == ST_FINISH) 
            post_spike_latched <= 1'b0;
        else if (spike_out) 
            post_spike_latched <= 1'b1;
    end

    // 784-bit 脈衝 Buffer 
    spike_buffer_layer1 #(
        .INPUT_WIDTH(8), .TOTAL_PIXELS(784)
    ) u_spike_buf (
        .clk(clk), .rst_n(rst_n),
        .l1_spike_data(spike_data_out),
        .l1_valid(spike_valid_out), 
        .buf_ready(),
        .l2_full_spike_vector(L2_input_vector),
        .l2_valid(),
        .l2_done(current_mode == ST_FINISH) 
    );

    // =======================================================
    // Data Assembly & Pixel Valid Generator
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data_in  <= 64'd0;
            data_cnt       <= 2'd0;
            pixel_valid_in <= 1'b0;
        end else if (current_mode == ST_LOAD || current_mode == ST_INTEGRATE) begin
            pixel_data_in <= {data_in[15:0], pixel_data_in[63:16]};
            data_cnt <= data_cnt + 2'd1;
            pixel_valid_in <= (current_mode == ST_INTEGRATE) ? (data_cnt == 2'd3) : 1'b0;   
        end else begin
            data_cnt <= 2'd0;
            pixel_valid_in <= 1'b0;
        end
    end
    
    // =======================================================
    // ST_UPDATE 4-Cycle 排程控制器 (解決 Single Port SRAM 衝突)
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_addr <= 7'd0;
            upd_cnt     <= 2'd0;
        end else if (current_mode == ST_UPDATE) begin
            upd_cnt <= upd_cnt + 2'd1;
            if (upd_cnt == 2'd3 && update_addr < BATCH_NUM) begin
                update_addr <= update_addr + 7'd1;
            end
        end else begin
            update_addr <= 7'd0;
            upd_cnt     <= 2'd0;
        end
    end

    // 擷取對應地址的 Pre-spike 向量
    wire [7:0] current_pre_spike = (update_addr < BATCH_NUM) ? L2_input_vector[update_addr * 8 +: 8] : 8'd0;

    // --- 寫入數據穩定器 ---
    wire st_update_wr_trigger = (current_mode == ST_UPDATE) && (upd_cnt == 2'd2) && (update_addr < BATCH_NUM);

    // =======================================================
    // 記憶體控制多工 (MUX)
    // =======================================================
    // Write 仲裁
    assign wr_en     = (current_mode == ST_LOAD) ? (data_cnt == 2'd3) : (st_update_wr_trigger) ? any_stdp_write : 1'b0;
    assign wr_mask   = (current_mode == ST_LOAD) ? 8'hFF : write_en; 
    assign wr_weight = (current_mode == ST_LOAD) ? {data_in[15:0], pixel_data_in[63:16]} : weight_new;
    assign wr_row    = (current_mode == ST_LOAD) ? load_counter : update_addr;
    
    // Read 仲裁
    wire phase2_rd_en     = (current_mode == ST_UPDATE) && (update_addr < BATCH_NUM);
    wire effective_rd_en  = (current_mode == ST_UPDATE) ? phase2_rd_en : spike_valid_out;
    wire [6:0] effective_rd_row = (current_mode == ST_UPDATE) ? update_addr : (current_mode == ST_INTEGRATE) ? cur_batch_cnt : 7'd0;
    wire [7:0] we_pre_mask      = (current_mode == ST_UPDATE) ? 8'hFF : spike_data_out;

    // =======================================================
    // 模組實例化
    // =======================================================
    pre_synaptic_block #(
        .D_WIDTH      (D_WIDTH),    
        .BATCH_NUM    (BATCH_NUM),  
        .T_WIDTH      (T_WIDTH),    
        .ADDR_WIDTH   (ADDR_WIDTH)  
    ) u_pre_syn_blk (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (start),         
        .accumulate_en   (accumulate_en), 
        .pixel_valid_in  (pixel_valid_in),      
        .pixel_data_in   (pixel_data_in),   
        .cur_batch_cnt        (cur_batch_cnt),    
        .L1_busy         (),              
        .L1_done         (l1_done_wire),            
        .spike_data_out  (spike_data_out),    
        .spike_valid_out (spike_valid_out),    
        .trace_data_out  (trace_data_out),
        .trace_init_en   (current_mode == ST_LOAD && data_cnt == 2'd3 && load_counter < BATCH_NUM), 
        .trace_init_addr (load_counter),     
        .ext_addr        (effective_rd_row),
        .is_update_phase (current_mode == ST_UPDATE)
    );

    post_synaptic_block #(
        .V_WIDTH(V_WIDTH),    
        .T_WIDTH(T_WIDTH)    
    ) u_post_syn_blk (
        .clk            (clk),
        .rst_n          (rst_n),
        .update_en      (finish),           
        .accum_en       (rd_valid && current_mode == ST_INTEGRATE),   
        .weight_mem_in  (rd_weight),
        .spike_out      (spike_out),  
        .fire_in_latched (post_spike_latched), 
        .post_trace_8x  (post_trace_8x)
    );

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stdp_group
            stdp #(
                .WEIGHT_WIDTH(D_WIDTH),
                .TRACE_WIDTH(T_WIDTH),
                .SHIFT_LTP(2),
                .SHIFT_LTD(3)
            ) u_stdp (
                .clk           (clk),
                .rst_n         (rst_n),
                .pre_spike_in  (current_pre_spike[i]), // 直接吃組合邏輯
                .weight_old    (rd_weight[i*D_WIDTH +: D_WIDTH]), 
                .pre_trace     (trace_data_out[i*T_WIDTH +: T_WIDTH]), 
                .post_spike_in (post_spike_latched), 
                .post_trace    (post_trace_8x[i*T_WIDTH +: T_WIDTH]),
                .weight_new    (weight_new[i*D_WIDTH +: D_WIDTH]),
                .write_en      (write_en[i])
            );
        end
    endgenerate
    
    // Weight Memory
    we_unit_98x64 u_we (
        .clk        (clk),
        .rst_n      (rst_n),
        .rd_en      (effective_rd_en),      
        .rd_row     (effective_rd_row),      
        .pre_mask   (we_pre_mask),         
        .rd_weight  (rd_weight),
        .rd_valid   (rd_valid),  
        .wr_en      (wr_en),     
        .wr_mask    (wr_mask), 
        .wr_row     (wr_row),   
        .wr_weight  (wr_weight)    
    );

endmodule

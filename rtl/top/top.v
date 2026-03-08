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
    localparam ST_INTEGRATE = 3'd2; // 第一階段：積分掃描 (僅累加電位，存脈衝，不寫回)
    localparam ST_CHECK     = 3'd3; // 檢查發火：等待第 98 拍結束看是否發火
    localparam ST_UPDATE    = 3'd4; // 第二階段：統一更新 (重新掃描算 STDP 並單次寫回)
    localparam ST_FINISH    = 3'd5; 

    reg [2:0]  current_mode;
    reg [6:0]  load_counter; 
    reg [1:0]  data_cnt;     
    reg [63:0] pixel_data_in;
    reg        is_initialized; 

    reg        start;
    reg        accumulate_en;
    reg        pixel_valid_in; // 通知 Spike Gen 資料已備妥

    wire [63:0] rd_weight;      
    wire [6:0]  req_addr;         
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
    // 儲存第一階段收集的 784-bit 完整脈衝向量，供第二階段 0 延遲讀取
    wire [783:0] L2_input_vector;
    // 第二階段 (ST_UPDATE) 專用的位址掃描計數器 (0~97)
    reg [6:0] update_addr;
    // 全域發火狀態鎖存，供第二階段全體 Batch 共用判定 LTP
    reg       post_spike_latched;
    // --- 流水線時序對齊暫存器 ---
    // 將 0 延遲的 Pre-spike 打 2 拍，以對齊 SRAM 的 2 拍讀取延遲
    reg [7:0] pre_spike_pipe [0:1];
    reg [6:0] addr_pipe_n1; 
    reg [6:0] addr_pipe_n2;

    // 只要 8 個 STDP 模組中有任何一個要求更新權重，此訊號即為 1
    wire any_stdp_write = |write_en;
    // --- 讀取控制多工 (MUX) ---
    wire [6:0] effective_rd_row = (current_mode == ST_UPDATE) ? update_addr : (req_addr - 7'd1);
    wire       phase2_rd_en     = (current_mode == ST_UPDATE) && (update_addr < BATCH_NUM);
    wire       effective_rd_en  = (current_mode == ST_UPDATE) ? phase2_rd_en : spike_valid_out;
    wire [7:0] we_pre_mask      = (current_mode == ST_UPDATE) ? 8'hFF : spike_data_out;
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
                        end else begin
                            current_mode <= ST_INTEGRATE;
                            start <= 1'b1;
                            accumulate_en <= 1'b1;
                        end
                    end
                end
                ST_LOAD: begin
                    if (data_cnt == 2'd3) begin
                        if (load_counter == BATCH_NUM - 1) begin
                            current_mode   <= ST_IDLE; 
                            is_initialized <= 1'b1;
                            load_counter   <= 7'd0;
                        end else begin
                            load_counter <= load_counter + 1'b1;
                        end
                    end
                end
                ST_INTEGRATE: begin
                    if (l1_done_wire) current_mode <= ST_CHECK;
                end
                ST_CHECK: begin
                    current_mode <= ST_UPDATE;
                end
                ST_UPDATE: begin
                    if (update_addr == BATCH_NUM && rd_valid == 1'b0 && wr_en == 1'b0) 
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
        .l1_valid(spike_valid_out && current_mode == ST_INTEGRATE), 
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
    // 更新階段位址掃描與流水線對齊
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_addr       <= 7'd0;
            pre_spike_pipe[0] <= 8'd0; 
            pre_spike_pipe[1] <= 8'd0;
            addr_pipe_n1 <= 7'd0;
            addr_pipe_n2 <= 7'd0;
        end else if (current_mode == ST_UPDATE) begin
            if (update_addr < BATCH_NUM) update_addr <= update_addr + 7'd1;
            
            // 第一拍延遲 (加上越界保護)
            pre_spike_pipe[0] <= (update_addr < BATCH_NUM) ? L2_input_vector[update_addr * 8 +: 8] : 8'd0;
            addr_pipe_n1      <= update_addr;  
            // Weight SRAM 與 Trace SRAM 都在此時收到 effective_rd_row，並自動在 2 拍後吐出資料
            // 第二拍延遲
            pre_spike_pipe[1] <= pre_spike_pipe[0];
            addr_pipe_n2      <= addr_pipe_n1; 
        end else begin
            update_addr       <= 7'd0;
        end
    end

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
        .pixel_data_in   (pixel_data_in),   // 接回組裝好的 64-bit 暫存器
        .req_addr        (req_addr),    
        .L1_busy         (),              
        .L1_done         (l1_done_wire),            
        .spike_data_out  (spike_data_out),    
        .spike_valid_out (spike_valid_out),    
        .trace_data_out  (trace_data_out),     
        // 將第二階段的地址餵給 Pre-trace SRAM，它會在 2 拍後吐出資料
        .ext_addr        (effective_rd_row),
        .is_update_phase (current_mode == ST_UPDATE)
    );

    post_synaptic_block #(
        .V_WIDTH(V_WIDTH),    
        .T_WIDTH(T_WIDTH)    
    ) u_post_syn_blk (
        .clk            (clk),
        .rst_n          (rst_n),
        .update_en       (finish),           // 僅在最後一拍更新
        .accum_en       (rd_valid && current_mode == ST_INTEGRATE),   
        .weight_mem_in  (rd_weight),
        .spike_out      (spike_out),  
        .fire_in_latched (post_spike_latched), // 餵入本輪發火紀錄
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
                // 0 延遲的 Spike 被人工打了 2 拍
                .pre_spike_in  (pre_spike_pipe[1][i]),
                // 2 拍延遲的 Weight 直接接
                .weight_old    (rd_weight[i*D_WIDTH +: D_WIDTH]), 
                // 2 拍延遲的 Trace 直接接
                .pre_trace     (trace_data_out[i*T_WIDTH +: T_WIDTH]), 
                .post_spike_in (post_spike_latched), 
                .post_trace    (post_trace_8x[i*T_WIDTH +: T_WIDTH]),
                .weight_new    (weight_new[i*D_WIDTH +: D_WIDTH]),
                .write_en      (write_en[i])
            );
        end
    endgenerate
    
    // =======================================================
    // Write Arbitration (權重記憶體寫入仲裁)
    // =======================================================
    assign wr_en = (current_mode == ST_LOAD) ? (data_cnt == 2'd3) : 
                   (current_mode == ST_UPDATE && rd_valid) ? any_stdp_write : 1'b0;
                         
    assign wr_mask   = (current_mode == ST_LOAD) ? 8'hFF : write_en; 
    assign wr_weight = (current_mode == ST_LOAD) ? pixel_data_in : weight_new; 
    assign wr_row    = (current_mode == ST_LOAD) ? addr_in : addr_pipe_n2;
 
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


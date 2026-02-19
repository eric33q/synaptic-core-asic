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

    reg [1:0]  current_mode;
    reg [6:0]  load_counter; 
    reg [1:0]  data_cnt;     
    reg [63:0] data_64bit_reg;
    reg        is_initialized; 

    reg        sg_start;
    reg        sg_accumulate_en;
    reg        pixel_valid; // [新增] 用來通知 Spike Gen 資料已備妥

    reg [6:0] addr_pipe_n1; 
    reg [6:0] addr_pipe_n2;

    wire [63:0] w_weight_data;      
    wire [6:0]  w_req_addr;         
    wire        w_weight_valid;     
    
    wire [7:0]  w_l2_spike;         
    wire        w_l2_valid;         
    wire [D_WIDTH*T_WIDTH-1:0] w_l1_trace; 
    
    wire [63:0] w_post_trace_8x;    
    
    wire [63:0] w_stdp_new_weight;  
    wire [7:0]  w_stdp_wr_be;       
    
    wire        final_wr_en;
    wire [7:0]  final_wr_mask;
    wire [63:0] final_wr_data;
    wire [6:0]  final_wr_addr;

    localparam ST_IDLE   = 2'b00; 
    localparam ST_LOAD   = 2'b01; 
    localparam ST_WORK   = 2'b10; 
    localparam ST_FINISH = 2'b11; 

    // =======================================================
    // FSM 與 核心控制邏輯
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode   <= ST_IDLE;
            load_counter   <= 7'd0;
            is_initialized <= 1'b0;
            sg_start       <= 1'b0;
            sg_accumulate_en <= 1'b0;
        end else begin
            sg_start <= 1'b0;

            case (current_mode)
                ST_IDLE: begin
                    if (start_loading) begin
                        if (!is_initialized) begin
                            current_mode <= ST_LOAD;
                            sg_start <= 1'b1;
                            sg_accumulate_en <= 1'b0;
                        end else begin
                            current_mode <= ST_WORK;
                            sg_start <= 1'b1;
                            sg_accumulate_en <= 1'b1;
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

                ST_WORK: begin
                    if (finish) current_mode <= ST_FINISH;
                end

                ST_FINISH: begin
                    current_mode <= ST_IDLE;
                end

                default: current_mode <= ST_IDLE;
            endcase
        end
    end

    // =======================================================
    // Data Assembly & Pixel Valid Generator
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_64bit_reg <= 64'd0;
            data_cnt <= 2'd0;
            pixel_valid <= 1'b0;
        end else if (current_mode == ST_LOAD || current_mode == ST_WORK) begin
            data_64bit_reg <= {data_in[15:0], data_64bit_reg[63:16]};
            data_cnt <= data_cnt + 1'b1;
            
            // [關鍵] 每 4 拍湊滿一次，發出 1 拍的 Valid 給 Spike Gen
            if (current_mode == ST_WORK && data_cnt == 2'd3)
                pixel_valid <= 1'b1;
            else
                pixel_valid <= 1'b0;
                
        end else begin
            data_cnt <= 2'd0;
            pixel_valid <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_pipe_n1 <= 7'd0;
            addr_pipe_n2 <= 7'd0;
        end else begin
            addr_pipe_n1 <= w_req_addr;  
            addr_pipe_n2 <= addr_pipe_n1; 
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
    ) u_spike_gen (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (sg_start),         
        .accumulate_en   (sg_accumulate_en), 
        .pixel_valid_in  (pixel_valid),      // 👈 [新增] 傳入 Valid 信號
        .pixel_data_in   (data_64bit_reg),   // 接回組裝好的 64-bit 暫存器
        .req_addr        (w_req_addr),    
        .L1_busy         (busy),              
        .L1_done         (finish),            
        .spike_data_out  (w_l2_spike),    
        .spike_valid_out (w_l2_valid),    
        .trace_data_out  (w_l1_trace)     
    );

    post_synaptic_block #(
        .V_WIDTH(V_WIDTH),    
        .T_WIDTH(T_WIDTH)    
    ) u_post_block (
        .clk            (clk),
        .rst_n          (rst_n),
        .update_en      (finish),       
        .accum_en       (w_l2_valid),   
        .weight_mem_in  (w_weight_data),
        .spike_out      (spike_out),    
        .post_trace_8x  (w_post_trace_8x)
    );

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stdp_group
            stdp #(
                .SHIFT_LTP(2),
                .SHIFT_LTD(3)
            ) u_stdp (
                .clk           (clk),
                .rst_n         (rst_n),
                .pre_spike_in  (w_l2_spike[i]),
                .post_spike_in (spike_out),
                .weight_old    (w_weight_data[i*D_WIDTH +: D_WIDTH]), 
                .pre_trace     (w_l1_trace[i*T_WIDTH +: T_WIDTH]), 
                .post_trace    (w_post_trace_8x[i*T_WIDTH +: T_WIDTH]),
                .weight_new    (w_stdp_new_weight[i*D_WIDTH +: D_WIDTH]),
                .write_en      (w_stdp_wr_be[i])
            );
        end
    endgenerate
    
    // =======================================================
    // Write Arbitration (權重記憶體寫入仲裁)
    // =======================================================
    // [修正] ST_WORK 期間只要有 STDP 寫入請求就放行，不再只等 finish
    assign final_wr_en = (current_mode == ST_LOAD) ? (data_cnt == 2'd3) : 
                         (current_mode == ST_WORK) ? (|w_stdp_wr_be) : 1'b0;
                         
    assign final_wr_mask = (current_mode == ST_LOAD) ? 8'hFF : w_stdp_wr_be; 
    assign final_wr_data = (current_mode == ST_LOAD) ? data_64bit_reg : w_stdp_new_weight; 
    assign final_wr_addr = (current_mode == ST_LOAD) ? addr_in : addr_pipe_n2;
 
    // Weight Memory
    we_unit_98x64 u_weight_mem (
        .clk        (clk),
        .rst_n      (rst_n),
        .rd_en      (w_l2_valid),      
        .rd_row     (w_req_addr),      
        .pre_mask   (w_l2_spike),           
        .rd_weight  (w_weight_data),
        .rd_valid   (w_weight_valid),  
        .wr_en      (final_wr_en),     
        .wr_mask    (final_wr_mask), 
        .wr_row     (final_wr_addr),   
        .wr_weight  (final_wr_data)    
    );

endmodule
module top #(
    parameter D_WIDTH      = 8,    // 數據位寬 (如權重與像素)
    // --- Spike Generator / Batch 參數 ---
    parameter BATCH_NUM    = 98,   // 處理的資料批次數量 (對應 98 組 64-bit)
    parameter ADDR_WIDTH   = 7,    // SRAM 位址位元寬
    // --- LIF 神經元核心參數 ---
    parameter I_WIDTH      = 18,   // 電流累積運算位寬
    parameter V_WIDTH      = 19,   // 膜電位運算位寬
    parameter THRESHOLD    = 800,  // 發火閾值 (V_th)
    parameter LEAK_SHIFT   = 3,    // 漏電率係數 (V_leak >> LEAK_SHIFT)
    parameter REF_PERIOD   = 3,    // 不應期週期數
    // --- STDP 參數 ---
    parameter T_WIDTH      = 8     // Trace 位寬
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_loading,
    input  wire [6:0]  addr_in,     // SRAM 位址輸入 (載入模式用)
    input  wire [15:0] data_in,     // 16-bit 多工輸入
    output wire        spike_out,   // 神經元最終發火信號
    output wire        busy,        // 系統忙碌
    output wire        finish       // 運算完成
);
    reg [1:0]  current_mode;
    reg [6:0]  load_counter; 
    reg [1:0]  data_cnt;     
    reg [63:0] data_64bit_reg;
    reg        is_initialized; // 記錄是否已完成第一次載入
    // Pipeline 地址延遲 (用於 Cycle N+2 寫回)
    reg [6:0] addr_pipe_n1; 
    reg [6:0] addr_pipe_n2;
    // SRAM 讀取相關
    wire [63:0] w_weight_data;      // 從 SRAM 讀出的權重
    wire [6:0]  w_req_addr;         // Spike Gen 請求的讀取位址
    wire        w_weight_valid;     // 用來接收 SRAM 讀取有效的訊號
    // Layer 1 Spike Gen 相關
    wire [7:0]  w_l2_spike;         // 8 路像素脈衝
    wire        w_l2_valid;         // 脈衝有效 (accumulate_en)
    wire [D_WIDTH*T_WIDTH-1:0] w_l1_trace; // 用來接收 Layer 1 產生的 Pre-trace
    // Post-Synaptic 相關
    wire [63:0] w_post_trace_8x;    // 鎖存後的 Post-trace (給 STDP 用)
    // STDP 相關
    wire [63:0] w_stdp_new_weight;  // 8 個引擎算出的新權重
    wire [7:0]  w_stdp_wr_be;       // 8 個引擎的寫入請求 (Byte Mask)
    // 寫入仲裁相關
    wire        final_wr_en;
    wire [7:0] final_wr_mask;
    wire [63:0] final_wr_data;
    wire [6:0]  final_wr_addr;

    localparam ST_IDLE   = 2'b00; // 等待啟動訊號
    localparam ST_LOAD   = 2'b01; // 載入狀態：搬運初始權重
    localparam ST_WORK   = 2'b10; // 工作狀態：讀取像素並執行 SNN 運算
    localparam ST_FINISH = 2'b11; // 緩衝狀態
    // FSM 主邏輯
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode   <= ST_IDLE;
            load_counter   <= 7'd0;
            is_initialized <= 1'b0;
        end else begin
            case (current_mode)
                ST_IDLE: begin
                    if (start_loading)
                        // 利用已儲存的狀態判定跳轉 
                        current_mode <= (is_initialized) ? ST_WORK : ST_LOAD;
                end

                ST_LOAD: begin
                    // 確保資料組裝完成後再移動地址 
                    if (data_cnt == 2'd3) begin
                        if (load_counter == 7'd97) begin
                            current_mode   <= ST_WORK;
                            is_initialized <= 1'b1;
                            load_counter   <= 7'd0;
                        end else begin
                            load_counter <= load_counter + 1'b1;
                        end
                    end
                end

                ST_WORK: begin
                    // 等待神經元核心完成 BATCH_NUM 的運算 
                    if (finish) current_mode <= ST_FINISH;
                end

                ST_FINISH: begin
                    // 額外留一拍緩衝，確保 STDP Pipeline 寫回完成
                    current_mode <= ST_IDLE;
                end

                default: current_mode <= ST_IDLE;
            endcase
        end
    end

    // Pipeline 地址緩存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_pipe_n1 <= 7'd0;
            addr_pipe_n2 <= 7'd0;
        end else begin
            addr_pipe_n1 <= w_req_addr;  
            addr_pipe_n2 <= addr_pipe_n1; // Cycle N+1 -> N+2
        end
    end
  
    // Data Assembly(16-to-64 bit)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_64bit_reg <= 64'd0;
            data_cnt <= 2'd0;
        end else if (current_mode == 2'b01||current_mode == 2'b10) begin
                data_64bit_reg[63:0]  <= {data_in[15:0],data_64bit_reg[63:16]};
           // case(data_cnt)
           //     2'd0: data_64bit_reg[15:0]  <= data_in;
        //	2'd1: data_64bit_reg[31:16] <= data_in;
         //       2'd2: data_64bit_reg[47:32] <= data_in;
           //    2'd3: data_64bit_reg[63:48] <= data_in;
           // endcase
            data_cnt <= data_cnt + 1'b1;
        end else begin
            data_cnt <= 2'd0;
        end
    end

    // 模組實例化 (Sub-modules)
    pre_synaptic_block #(
        .D_WIDTH      (D_WIDTH),    // 8 pixels
        .BATCH_NUM    (BATCH_NUM),  // 98 batches
        .T_WIDTH      (T_WIDTH),    // 8 bits
        .ADDR_WIDTH   (ADDR_WIDTH)  // 7 bits
    ) u_spike_gen (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (current_mode == 2'b10), 
        .accumulate_en   (current_mode == 2'b10&& data_cnt == 2'd3),
        .pixel_data_in   (data_64bit_reg), // 接外部像素來源   
        .req_addr        (w_req_addr),    
        // 狀態輸出
        .L1_busy         (busy),              
        .L1_done         (finish),            
        // 核心輸出：對接 STDP 與 Neuron
        .spike_data_out  (w_l2_spike),    // 輸出原始脈衝
        .spike_valid_out (w_l2_valid),    // 輸出有效訊號
        .trace_data_out  (w_l1_trace)     // 輸出計算好的 Pre-trace (64 bits)
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
    
    // Write Arbitration
    // 只有在 Mode 10 且真的有 Byte 要寫入時才拉高
    assign final_wr_en = (current_mode == ST_LOAD) ? (data_cnt == 2'd3) : 
                         (current_mode == ST_WORK && finish) ? (|w_stdp_wr_be === 1'b1) : 1'b0;
    assign final_wr_mask = (current_mode == ST_LOAD) ? 8'hFF: w_stdp_wr_be; 
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

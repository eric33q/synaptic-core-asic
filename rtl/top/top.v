module top #(
    parameter D_WIDTH      = 8,    // 數據位寬 (如權重與像素) [cite: 1, 36, 42]
    
    // --- Spike Generator / Batch 參數 ---
    parameter BATCH_NUM    = 98,   // 處理的資料批次數量 (對應 98 組 64-bit) [cite: 36]
    parameter ADDR_WIDTH   = 7,    // SRAM 位址位元寬 (128 抽頭需 7-bit) [cite: 42]
    
    // --- LIF 神經元核心參數 ---
    parameter I_WIDTH      = 18,   // 電流累積運算位寬 [cite: 1]
    parameter V_WIDTH      = 19,   // 膜電位運算位寬 [cite: 1]
    parameter THRESHOLD    = 800,  // 發火閾值 (V_th) [cite: 1]
    parameter LEAK_SHIFT   = 3,    // 漏電率係數 (V_leak >> LEAK_SHIFT) [cite: 1]
    parameter REF_PERIOD   = 3     // 不應期週期數 [cite: 1]
    )(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  mode_sel,    // 01: 載入數據 (影像或權重), 10: 開始推論
    input  wire [6:0]  addr_in,     // SRAM 位址輸入
    input  wire [7:0]  mask_in,     // STDP 寫入遮罩 (8-bit)
    input  wire [15:0] data_in,     // 16-bit 多工輸入 (需 4 拍完成 64-bit)
    output wire        spike_out,   // 神經元最終發火信號
    output wire        busy,        // 系統忙碌
    output wire        finish       // 運算完成
);

    // --- 內部連線與暫存器 ---
    reg  [63:0] data_64bit_reg;
    reg  [1:0]  data_cnt;
    wire [63:0] w_weight_data;      // 從 SRAM 讀出的權重
    wire [7:0]  w_l2_spike;         // 來自產生器的脈衝數據 
    wire        w_l2_valid;         // 脈衝有效信號 
    wire [6:0]  w_req_addr;         // 產生器要求的位址 

    // --- 1. 16-bit 轉 64-bit 多工邏輯 (符合 40-pin) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_64bit_reg <= 64'd0;
            data_cnt <= 2'd0;
        end else if (mode_sel == 2'b01) begin
            case(data_cnt)
                2'd0: data_64bit_reg[15:0]  <= data_in;
                2'd1: data_64bit_reg[31:16] <= data_in;
                2'd2: data_64bit_reg[47:32] <= data_in;
                2'd3: data_64bit_reg[63:48] <= data_in;
            endcase
            data_cnt <= data_cnt + 1'b1;
        end else begin
            data_cnt <= 2'd0;
        end
    end

    // --- 2. 脈衝產生器 (Spike Generator) ---
    layer1_system_top #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM)
    ) u_spike_gen (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (mode_sel == 2'b10), // 推論模式下啟動 
        .accumulate_en  (1'b0),
        .pixel_data_in  (data_64bit_reg),    // 影像像素輸入 
        .req_addr       (w_req_addr),        // 自動產生的讀取位址 
        .L2_spike_data  (w_l2_spike),        // 輸出脈衝 
        .L2_valid       (w_l2_valid),        // 脈衝有效 
        .L1_busy        (busy),              // 
        .L1_done        (finish)             // 
    );

    // --- 3. 權重記憶體 (Weight Memory) ---
    we_unit_98x64 u_weight_mem (
        .clk        (clk),
        .rst_n      (rst_n),
        // 讀取：追隨產生器的位址與有效信號
        .rd_en      (w_l2_valid),            // 有脈衝時才讀權重 
        .rd_row     (w_req_addr),            // 讀取對應的權重行 
        .pre_mask   (w_l2_spike),            // 來自產生器的脈衝作為讀取遮罩
        .rd_weight  (w_weight_data),         // 輸出 64-bit 權重 
        // 寫入：用於 STDP 或初始載入
        .wr_en      (mode_sel == 2'b01 && data_cnt == 2'd3),
        .wr_mask    (mask_in),               // 支援 Byte Mask 
        .wr_row     (addr_in),
        .wr_weight  (data_64bit_reg)
    );

    // --- 4. LIF 神經元 (LIF Unit) ---
    lif_unit_784to1 #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) u_lif_core (
        .clk        (clk),
        .rst_n      (rst_n),
        // 注意：這裡假設 lif_unit 接收 64-bit 權重並在內部根據脈衝加權
        .weight_mem (w_weight_data),         // 接收來自 SRAM 的權重 [cite: 1]
        .post_spike (spike_out),             // 神經元發火 [cite: 2]
        .V_mem_out  ()
    );

endmodule
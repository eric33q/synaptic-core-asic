module top (
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
        .D_WIDTH(8),
        .BATCH_NUM(98)
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
        .pre_mask   (8'hFF), 
        .rd_weight  (w_weight_data),         // 輸出 64-bit 權重 
        // 寫入：用於 STDP 或初始載入
        .wr_en      (mode_sel == 2'b01 && data_cnt == 2'd3),
        .wr_mask    (mask_in),               // 支援 Byte Mask 
        .wr_row     (addr_in),
        .wr_weight  (data_64bit_reg)
    );

    // --- 4. LIF 神經元 (LIF Unit) ---
    lif_unit_784to1 #(
        .D_WIDTH(8),
        .V_WIDTH(19),
        .THRESHOLD(800)
    ) u_lif_core (
        .clk        (clk),
        .rst_n      (rst_n),
        // 注意：這裡假設 lif_unit 接收 64-bit 權重並在內部根據脈衝加權
        .weight_mem (w_weight_data),         // 接收來自 SRAM 的權重 [cite: 1]
        .post_spike (spike_out),             // 神經元發火 [cite: 2]
        .V_mem_out  ()
    );

endmodule
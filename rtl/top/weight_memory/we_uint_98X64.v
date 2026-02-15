module we_unit_98x64(
    input  wire         clk,
    input  wire         rst_n,

    // 讀取權重介面
    input  wire         rd_en,
    input  wire [6:0]   rd_row,
    input  wire [7:0]   pre_mask,   // 從產生器來的pre_spike 
    output reg  [63:0]  rd_weight,
    output reg          rd_valid,

    // 寫入權重介面
    input  wire         wr_en,
    input  wire [7:0]   wr_mask,    // 從STDP來的訊號，8-bit 寫入遮罩，對應 8 個 Byte
    input  wire [6:0]   wr_row,
    input  wire [63:0]   wr_weight
);

    // --- 1. 內部信號定義 ---
    wire [63:0] sram_q;         // SRAM 輸出的原始數據
    wire [63:0] sram_d;         // 準備寫入 SRAM 的數據
    wire [63:0] sram_bw_en;     // Byte Write Enable (通常低位元有效)
    wire [6:0]  sram_addr;
    wire        sram_cen;       // Chip Enable
    wire        sram_wen;       // Write Enable

    // --- 2. 寫入邏輯：Byte Write Enable 設定 ---
    // 將 wr_mask (0~7) 轉換為 64-bit 的寫入遮罩
    // 假設 SRAM 的 BWEN 是 Active Low (0 表示寫入，1 表示遮蔽)
    assign sram_bw_en = {
    {8{!wr_mask[7]}},
    {8{!wr_mask[6]}},
    {8{!wr_mask[5]}},
    {8{!wr_mask[4]}},
    {8{!wr_mask[3]}},
    {8{!wr_mask[2]}},
    {8{!wr_mask[1]}},
    {8{!wr_mask[0]}}
};
    
    // 寫入數據對齊到對應的 Byte 位置
    assign sram_d = wr_weight; 

    // 單埠 SRAM 位址多工：寫入優先於讀取 (或視你的仲裁邏輯而定)
    assign sram_addr = wr_en ? wr_row : rd_row;
    assign sram_cen  = !(rd_en || wr_en); // 有讀或寫才啟動
    assign sram_wen  = !wr_en;            // 0 為寫入, 1 為讀取

    // --- 3. 實例化 SRAM IP (此名稱需對應你 Compiler 產出的模組名) ---
    sram_sp_128x64 your_instance_name (
        .CLK  (clk),
        .CEN  (sram_cen),
        .WEN  (sram_wen),
        .BWEN (sram_bw_en), // 這裡使用了 Byte Write 功能
        .A    (sram_addr),
        .D    (sram_d),
        .Q    (sram_q)
    );

    // --- 4. 處理讀取 Latency 與 Mask ---
    reg [7:0] pre_mask_d1;
    reg       rd_en_d1;

    // 將 Mask 與讀取訊號延遲一拍，以對齊 SRAM 輸出的數據 Q
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_d1    <= 1'b0;
            pre_mask_d1 <= 8'd0;
        end else begin
            rd_en_d1    <= rd_en;
            pre_mask_d1 <= pre_mask;
        end
    end

    // 展開 Mask (對齊延遲後的 pre_mask)
    wire [63:0] mask64_d1 = {
        {8{pre_mask_d1[7]}}, 
        {8{pre_mask_d1[6]}}, 
        {8{pre_mask_d1[5]}}, 
        {8{pre_mask_d1[4]}},
        {8{pre_mask_d1[3]}}, 
        {8{pre_mask_d1[2]}}, 
        {8{pre_mask_d1[1]}}, 
        {8{pre_mask_d1[0]}}
    };

    // 最終輸出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_weight <= 64'd0;
            rd_valid  <= 1'b0;
        end else begin
            rd_valid <= rd_en_d1;
            if (rd_en_d1) begin
                rd_weight <= sram_q & mask64_d1;
            end else begin
                rd_weight <= 64'd0;
            end
        end
    end

endmodule
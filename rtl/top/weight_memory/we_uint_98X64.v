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
    wire [7:0] sram_bw_en;     // Byte Write Enable (通常低位元有效)
    reg  [6:0] sram_addr;
    reg        sram_cen;       // Chip Enable
    reg        sram_wen;       // Write Enable

    // --- 2. 寫入邏輯：Byte Write Enable 設定 ---
    assign sram_bw_en = ~wr_mask;
    assign sram_d = wr_weight; 

    // 單埠 SRAM 位址多工：寫入優先於讀取
    always @(posedge clk) begin
           sram_wen <= !wr_en;
           sram_addr <= wr_en ? wr_row : rd_row;
           sram_cen  <= !(rd_en || wr_en); // 有讀或寫才啟動
    end

    // --- 3. 實例化 SRAM ---
    sram_sp_128x64 u_sram (
        .CLK  (clk),
        .CEN  (sram_cen),
        .WEN  (sram_wen),
        .BWEN (sram_bw_en), // 這裡現在是 8-bit 對 8-bit
        .A    (sram_addr),
        .D    (wr_weight),
        .Q    (sram_q)
    );

    // --- 4. 處理讀取 Latency 與 Mask ---

    // 展開 Mask (對齊延遲後的 pre_mask)
    wire [63:0] mask64 = {
        {8{pre_mask[7]}}, 
        {8{pre_mask[6]}}, 
        {8{pre_mask[5]}}, 
        {8{pre_mask[4]}},
        {8{pre_mask[3]}}, 
        {8{pre_mask[2]}}, 
        {8{pre_mask[1]}}, 
        {8{pre_mask[0]}}
    };

    // 最終輸出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_weight <= 64'd0;
            rd_valid  <= 1'b0;
        end else begin
            rd_valid <= rd_en;
            if (rd_en) begin
                rd_weight <= sram_q & mask64;
            end else begin
                rd_weight <= 64'd0;
            end
        end
    end

endmodule

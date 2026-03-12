`timescale 1ns/1ps

module we_unit_98x64(
    input  wire         clk,
    input  wire         rst_n,

    // 讀取權重介面
    input  wire         rd_en,
    input  wire [6:0]   rd_row,
    input  wire [7:0]   pre_mask,   // 從產生器來的 pre_spike 
    output wire [63:0]  rd_weight,  // 注意這裡改成 wire 了！
    output reg          rd_valid,

    // 寫入權重介面
    input  wire         wr_en,
    input  wire [7:0]   wr_mask,    // 從 STDP 來的訊號，8-bit 寫入遮罩
    input  wire [6:0]   wr_row,
    input  wire [63:0]  wr_weight
);

    // --- 1. SRAM 控制組合邏輯 ---
    wire [63:0] sram_q;
    reg  [6:0]  sram_addr;
    reg         sram_cen ; 
    reg  [7:0]  sram_wen ;

    always @(posedge clk) begin
           sram_wen <=  wr_en ? ~wr_mask : 8'hFF; // 寫入時，mask 位為 0；不寫入時，全 1
           sram_addr <= wr_en ? wr_row : rd_row;
           sram_cen  <= !(rd_en || wr_en); // 有讀或寫才啟動
    end

    // --- 2. 解決 RTL 模擬 Hold Violation 的絕招：人工線延遲 ---
    // 讓訊號在 Clock 邊緣後 1ns 才改變，完美滿足 0.5ns 的 Hold Time 要求
    wire [6:0]  sram_addr_dly;
    wire        sram_cen_dly;
    wire [7:0]  sram_wen_dly;
    wire [63:0] sram_d_dly;

    assign #1 sram_addr_dly = sram_addr;
    assign #1 sram_cen_dly  = sram_cen;
    assign #1 sram_wen_dly  = sram_wen;
    assign #1 sram_d_dly    = wr_weight;

    // --- 3. 實例化 TSMC Foundry SRAM ---
    sram_sp_128x64_rf u_sram (
        .Q   (sram_q),
        .CLK (clk),
        .CEN (sram_cen_dly),
        .WEN (sram_wen_dly), 
        .A   (sram_addr_dly),
        .D   (sram_d_dly),
        .EMA (3'b000)
    );

    // --- 4. 處理 1-Cycle 讀取 Latency 對齊 ---
    // SRAM 出資料需要 1 拍，所以把 mask 打一拍，等資料出來再做 AND
    reg [7:0] pre_mask_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_valid    <= 1'b0;
            pre_mask_d1 <= 8'd0;
        end else begin
            rd_valid    <= rd_en;
            pre_mask_d1 <= pre_mask;
        end
    end

    wire [63:0] mask64 = {
        {8{pre_mask_d1[7]}}, 
        {8{pre_mask_d1[6]}}, 
        {8{pre_mask_d1[5]}}, 
        {8{pre_mask_d1[4]}},
        {8{pre_mask_d1[3]}}, 
        {8{pre_mask_d1[2]}}, 
        {8{pre_mask_d1[1]}}, 
        {8{pre_mask_d1[0]}}
    };

    // 輸出端直接組合邏輯對接，達成完美的 1 拍讀取延遲
    assign rd_weight = rd_valid ? (sram_q & mask64) : 64'd0;

endmodule

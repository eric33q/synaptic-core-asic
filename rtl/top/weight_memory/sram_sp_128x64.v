module sram_sp_128x64 (
// 行為模擬階段:SRAM 模型
    input  wire        CLK,
    input  wire        CEN,  // Chip Enable (Active Low)
    input  wire        WEN,  // Write Enable (Active Low)
    input  wire [7:0]  BWEN, // 輸入改為 8-bit Byte Mask (Active Low)
    input  wire [6:0]  A,    // Address
    input  wire [63:0] D,    // Data In
    output wire [63:0] Q     // Data Out
);

    reg [63:0] mem [0:127];
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            mem[i] = 64'd0;
        end
    end
    // --- 讀取操作 ---
    assign Q = mem[A];
    always @(posedge CLK) begin
        if (!CEN) begin
            // --- 寫入操作 ---
            if (!WEN) begin
                // 內部的 Byte-wise 寫入邏輯
                // i 代表 Byte 的索引 (0~7)
                for (i = 0; i < 8; i = i + 1) begin
                    // 如果該 Byte 的遮罩是 0 (Active Low)，則寫入該 Byte (8 bits)
                    if (BWEN[i] == 1'b0) begin
                        mem[A][i*8 +: 8] <= D[i*8 +: 8];
                    end
                    // 否則保持原值
                end
            end 
        end
    end

endmodule


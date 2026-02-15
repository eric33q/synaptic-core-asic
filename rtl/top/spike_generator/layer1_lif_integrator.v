`timescale 1ns/1ps

module layer1_lif_integrator #(
    parameter D_WIDTH = 8
)(
    input  wire [D_WIDTH-1:0] V_leak,
    input  wire [D_WIDTH-1:0] i_syn,  // 來自像素的輸入
    output wire [D_WIDTH-1:0] V_next
);
    wire [D_WIDTH:0] sum_temp; // 多 1 bit 用來檢查溢位

    assign sum_temp = V_leak + i_syn;

    // 飽和運算 (Saturation Logic)：
    // 若相加結果超過 255 (sum_temp[8] 為 1)，則鎖定在最大值 255
    assign V_next = (sum_temp[D_WIDTH]) ? {D_WIDTH{1'b1}} : sum_temp[D_WIDTH-1:0];

endmodule
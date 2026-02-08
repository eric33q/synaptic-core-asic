`timescale 1ns/1ps

module lif_th_cmp #(
    parameter D_WIDTH   = 8,
    parameter THRESHOLD = 200
)(
    input  wire [D_WIDTH-1:0] V_mem,
    output wire spike
);
    // 當電壓大於等於閾值時，產生脈衝
    assign spike = (V_mem >= THRESHOLD);

endmodule
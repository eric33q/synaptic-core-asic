module lif_th_cmp #(
    parameter V_WIDTH   = 19,
    parameter THRESHOLD = 800
)(
    input  wire [V_WIDTH-1:0] V_mem,
    output wire spike
);
    // 大於閥值=>spike
    assign spike = (V_mem >= THRESHOLD);
endmodule

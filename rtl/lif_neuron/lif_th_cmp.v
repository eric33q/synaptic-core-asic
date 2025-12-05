module lif_th_cmp #(
    parameter D_WIDTH   = 8,
    parameter THRESHOLD = 200
)(
    input  wire [D_WIDTH-1:0] V_mem,
    output wire spike
);
    // 大於閥值=>spike
    assign spike = (V_mem >= THRESHOLD);
endmodule
module lif_integrator #(
    parameter D_WIDTH = 8
)(
    input  wire [D_WIDTH-1:0] V_leak,
    input  wire [D_WIDTH-1:0] i_syn,
    output wire [D_WIDTH-1:0] V_next,
    output wire V_next_valid
);
    // 用多1bit來檢查溢位
    wire [D_WIDTH:0] sum_temp;

    //i_syn不為0時,V_next_valid為1
    assign V_next_valid = (|i_syn);
    assign sum_temp = V_leak + i_syn;
    //如果有溢出，拉到[D_WIDTH-1:0]的最高
    assign V_next = (sum_temp[D_WIDTH]) ? {D_WIDTH{1'b1}} : sum_temp[D_WIDTH-1:0];

endmodule
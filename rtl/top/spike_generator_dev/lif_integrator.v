`timescale 1ns/1ps

module lif_integrator #(
    parameter D_WIDTH = 8
)(
    input  wire [D_WIDTH-1:0] V_leak,
    input  wire [D_WIDTH-1:0] i_syn,
    output wire [D_WIDTH-1:0] V_next
);
    wire [D_WIDTH:0] sum_temp;
    assign sum_temp = V_leak + i_syn;
    assign V_next = (sum_temp[D_WIDTH]) ? {D_WIDTH{1'b1}} : sum_temp[D_WIDTH-1:0];

endmodule
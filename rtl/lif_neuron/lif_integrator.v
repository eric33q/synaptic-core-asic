`timescale 1ns/1ps
module lif_integrator #(
    parameter V_WIDTH = 15,  // 膜電位位寬
    parameter I_WIDTH = 15  // 總突觸電流位寬
)(
    input  wire [V_WIDTH-1:0] V_leak,
    input  wire [I_WIDTH-1:0] i_syn,
    output wire [V_WIDTH-1:0] V_next,
    output wire V_next_valid
);
    // 為了處理不同位寬的加總，建立最大位寬的暫存
     localparam SUM_WIDTH = V_WIDTH + 1;
     wire [SUM_WIDTH-1:0] sum_temp;

    // i_syn 不為 0 時，V_next_valid 為 1
    assign V_next_valid = (|i_syn);
    assign sum_temp = {{SUM_WIDTH-V_WIDTH{1'b0}}, V_leak} + {{SUM_WIDTH-I_WIDTH{1'b0}}, i_syn};

    // 只要在 V_WIDTH 以上有任何位元為 1，就飽和到全 1，否則取低 V_WIDTH 位元
    assign V_next = (|sum_temp[SUM_WIDTH-1:V_WIDTH]) ? {V_WIDTH{1'b1}} : sum_temp[V_WIDTH-1:0];

endmodule

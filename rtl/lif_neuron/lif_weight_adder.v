`timescale 1ns/1ps
module lif_weight_adder #(
    parameter D_WIDTH = 8,   // 單一權重位寬
    parameter I_WIDTH = 15   // 8 個權重總和位寬，需確保 >= D_WIDTH+3
)
(
    input  wire [8*D_WIDTH-1:0] weight_flat,
    output wire [I_WIDTH-1:0] i_syn
);
    wire [D_WIDTH-1:0] weight [0:7];


    assign weight[0] = weight_flat[7:0];
    assign weight[1] = weight_flat[15:8];
    assign weight[2] = weight_flat[23:16];
    assign weight[3] = weight_flat[31:24];
    assign weight[4] = weight_flat[39:32];
    assign weight[5] = weight_flat[47:40];
    assign weight[6] = weight_flat[55:48];
    assign weight[7] = weight_flat[63:56];

    wire [I_WIDTH-1:0] sum_st1_0;
    wire [I_WIDTH-1:0] sum_st1_1;
    wire [I_WIDTH-1:0] sum_st1_2;
    wire [I_WIDTH-1:0] sum_st1_3;
    // 第一層加法器，兩兩相加
    assign sum_st1_0 = {{(I_WIDTH-D_WIDTH){1'b0}}, weight[0]} + {{(I_WIDTH-D_WIDTH){1'b0}}, weight[1]};
    assign sum_st1_1 = {{(I_WIDTH-D_WIDTH){1'b0}}, weight[2]} + {{(I_WIDTH-D_WIDTH){1'b0}}, weight[3]};
    assign sum_st1_2 = {{(I_WIDTH-D_WIDTH){1'b0}}, weight[4]} + {{(I_WIDTH-D_WIDTH){1'b0}}, weight[5]};
    assign sum_st1_3 = {{(I_WIDTH-D_WIDTH){1'b0}}, weight[6]} + {{(I_WIDTH-D_WIDTH){1'b0}}, weight[7]};
    // 第二層加法器，兩兩相加
    wire [I_WIDTH-1:0] sum_st2_0;
    wire [I_WIDTH-1:0] sum_st2_1;

    assign sum_st2_0 = sum_st1_0 + sum_st1_1;
    assign sum_st2_1 = sum_st1_2 + sum_st1_3;
    // 第三層加法器，最後相加
    assign i_syn = sum_st2_0 + sum_st2_1;

endmodule

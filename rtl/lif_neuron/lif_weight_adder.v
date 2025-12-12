module lif_weight_adder #(
    parameter D_WIDTH = 8,   // 單一權重位寬
    parameter I_WIDTH = 15   // 8 個權重總和位寬，需確保 >= D_WIDTH+3
)
(
    input  wire [D_WIDTH-1:0] weight[7:0],
    output wire [I_WIDTH-1:0] i_syn
);

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

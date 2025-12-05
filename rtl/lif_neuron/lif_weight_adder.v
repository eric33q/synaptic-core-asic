module lif_weight_adder #(
    parameter D_WIDTH = 8
    parameter I_WIDTH = 15 
)
(
    // 8 個 8-bit 輸入
    input  wire [D_WIDTH-1:0] weight[7:0],
    // 輸出：8 個數的總和 (需要 11-bit 以防溢位)
    output wire [I_WIDTH+1:0] i_syn
);

    // --- 第一層 (Stage 1): 8 輸入 -> 4 輸出 ---
    // 兩個 8-bit 相加 -> 9-bit 結果
    wire [8:0] sum_st1_0;
    wire [8:0] sum_st1_1;
    wire [8:0] sum_st1_2;
    wire [8:0] sum_st1_3;

    assign sum_st1_0 = weight[0] + weight[1];
    assign sum_st1_1 = weight[2] + weight[3];
    assign sum_st1_2 = weight[4] + weight[5];
    assign sum_st1_3 = weight[6] + weight[7];

    // --- 第二層 (Stage 2): 4 輸入 -> 2 輸出 ---
    // 兩個 9-bit 相加 -> 10-bit 結果
    wire [9:0] sum_st2_0;
    wire [9:0] sum_st2_1;

    assign sum_st2_0 = sum_st1_0 + sum_st1_1;
    assign sum_st2_1 = sum_st1_2 + sum_st1_3;

    // --- 第三層 (Stage 3): 2 輸入 -> 1 輸出 ---
    // 兩個 10-bit 相加 -> 11-bit 結果
    assign i_syn = sum_st2_0 + sum_st2_1;


endmodule
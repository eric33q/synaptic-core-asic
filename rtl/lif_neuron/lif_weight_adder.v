module lif_weight_adder #(
    parameter D_WIDTH = 8,   // 單一權重位寬
    parameter I_WIDTH = 18   // 8 個權重總和位寬，需確保 >= D_WIDTH+3
)
(
    input  wire [(8*D_WIDTH)-1:0] weight_bus, // 8 個 D_WIDTH 位元權重平坦化輸入
    output wire [I_WIDTH-1:0] i_syn
);

    wire [D_WIDTH-1:0] w[7:0];
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : unpack_weight
            assign w[i] = weight_bus[i*D_WIDTH +: D_WIDTH];
        end
    endgenerate

    wire [I_WIDTH-1:0] sum_st1_0, sum_st1_1, sum_st1_2, sum_st1_3;
    
    // 第一層加法器
    assign sum_st1_0 = w[0] + w[1];
    assign sum_st1_1 = w[2] + w[3];
    assign sum_st1_2 = w[4] + w[5];
    assign sum_st1_3 = w[6] + w[7];

    // 第二層加法器
    wire [I_WIDTH-1:0] sum_st2_0 = sum_st1_0 + sum_st1_1;
    wire [I_WIDTH-1:0] sum_st2_1 = sum_st1_2 + sum_st1_3;

    // 第三層加法器
    assign i_syn = sum_st2_0 + sum_st2_1;

endmodule

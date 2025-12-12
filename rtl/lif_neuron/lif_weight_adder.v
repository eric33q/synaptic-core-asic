module lif_weight_adder #(
    parameter D_WIDTH = 8,   // 單一權重位寬
    parameter I_WIDTH = 15   // 8 個權重總和位寬
)
(
    // 輸入是平的
    input  wire [(8*D_WIDTH)-1:0] weight_flat,
    output wire [I_WIDTH-1:0]     i_syn
);

    // 內部定義 wire 陣列方便加法
    wire [D_WIDTH-1:0] weight [7:0];

    // [相容性修正]：手動拆解 (Slicing)，取代 {>>{}}
    // 這樣寫 100% 不會報錯
    genvar g;
    generate
        for(g=0; g<8; g=g+1) begin : unpack_weight
            // Verilog-2001 Indexed Part Select 語法
            // 把長條切成 8 段，分別給 weight[0] ~ weight[7]
            assign weight[g] = weight_flat[ g*D_WIDTH +: D_WIDTH ];
        end
    endgenerate

    // 接下來是擴展 (Extension) 與加法，邏輯跟之前一樣
    wire [I_WIDTH-1:0] w_ext [7:0];
    generate
        for(g=0; g<8; g=g+1) begin : gen_ext
            // 符號擴展 (Sign Extension)
            assign w_ext[g] = { {(I_WIDTH-D_WIDTH){weight[g][D_WIDTH-1]}}, weight[g] };
        end
    endgenerate

    // 加法樹
    wire [I_WIDTH-1:0] sum_st1_0, sum_st1_1, sum_st1_2, sum_st1_3;
    wire [I_WIDTH-1:0] sum_st2_0, sum_st2_1;

    assign sum_st1_0 = w_ext[0] + w_ext[1];
    assign sum_st1_1 = w_ext[2] + w_ext[3];
    assign sum_st1_2 = w_ext[4] + w_ext[5];
    assign sum_st1_3 = w_ext[6] + w_ext[7];

    assign sum_st2_0 = sum_st1_0 + sum_st1_1;
    assign sum_st2_1 = sum_st1_2 + sum_st1_3;

    assign i_syn = sum_st2_0 + sum_st2_1;

endmodule
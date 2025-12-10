module lif_module #(
    parameter D_WIDTH    = 8,   // 數據位寬
    parameter I_WIDTH    = 15,  // 電流位寬
    parameter V_WIDTH    = 15,   // 電位位寬
    parameter THRESHOLD  = 200, // 發火閾值
    parameter LEAK_SHIFT = 3,   // 漏電移位
    parameter REF_PERIOD = 3    // 不應期週期數
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [D_WIDTH-1:0] weight[31:0][7:0],
    output wire [31:0]post_spike,
    output wire [V_WIDTH-1:0] V_mem_out[31:0]
);
    // 呼叫32個lif_unit組成64*32的LIF神經元
    genvar num;
    generate
        for(num = 0; num < 32; num = num + 1) begin : LIF_UNIT_ARRAY
            lif_unit_64to1 #(
                .D_WIDTH(D_WIDTH),
                .I_WIDTH(I_WIDTH),
                .V_WIDTH(V_WIDTH),
                .THRESHOLD(THRESHOLD),
                .LEAK_SHIFT(LEAK_SHIFT),
                .REF_PERIOD(REF_PERIOD)
            ) lif_unit_inst (
                .clk(clk),
                .rst_n(rst_n),
                .weight(weight[i]),
                .post_spike(post_spike[i]),
                .V_mem_out(V_mem_out[i])
            );
        end
    endgenerate
endmodule
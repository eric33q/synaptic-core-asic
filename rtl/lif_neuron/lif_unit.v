module lif_unit(clk, rst_n, i_syn, en, post_spike, V_mem_out);
    // I/O
    input clk, rst_n, en;
    input  [7:0] i_syn;
    output post_spike;
    output [7:0] V_mem_out;
    // Registers and wires
    reg [7:0] V_mem;
    wire V_next_valid;
    wire ref;
    wire [7:0] V_mem_leak;
    wire [7:0] V_mem_next;
    //測試輸出
    assign V_mem_out = V_mem;
    //膜電位更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            V_mem <= 8'd0;
        end else
        case ({ref, V_next_valid})
            2'b00: V_mem <= V_mem_leak; //漏電更新
            2'b01: V_mem <= V_mem_next; //積分更新
            2'b1x: V_mem <= 8'd0;       //不應期歸零
        endcase
    end
    //漏電單元
    lif_leak leak_unit(
        .clk(clk),
        .rst_n(rst_n),
        .V_in(V_mem),
        .V_leak(V_mem_leak)
    );
    //積分單元
    lif_integrator integrator_unit(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .V_leak(V_mem_leak),
        .i_syn(i_syn),
        .V_next(V_mem_next),
        .V_next_valid(V_next_valid)
    );
    //比較器
    lif_th_cmp th_cmp_unit(
        .V_mem(V_mem),
        .spike(post_spike)
    );
    //不應期控制單元
    lif_refrac_ctrl refrac_ctrl_unit(
        .clk(clk),
        .rst_n(rst_n),
        .post_spike(post_spike),
        .ref(ref)
    );

endmodule
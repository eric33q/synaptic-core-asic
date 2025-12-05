module lif_unit_64to1 #(
    parameter D_WIDTH    = 8,   // 數據位寬
    parameter THRESHOLD  = 200, // 發火閾值
    parameter LEAK_SHIFT = 3,   // 漏電移位
    parameter REF_PERIOD = 3    // 不應期週期數
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [D_WIDTH-1:0] i_syn,
    output wire post_spike,
    output wire [D_WIDTH-1:0] V_mem_out
);
    reg  [D_WIDTH-1:0] V_mem;
    wire [D_WIDTH-1:0] V_mem_leak;
    wire [D_WIDTH-1:0] V_mem_next; // 來自積分器的計算結果
    wire V_next_valid;             // 積分器指示是否有效
    wire ref_active;               // 不應期指示信號

    assign V_mem_out = V_mem;
    localparam ST_LEAK      = 2'b00;
    localparam ST_INTEGRATE = 2'b01;
    localparam ST_RESET     = 2'b10;
    reg [1:0] state_reg;
    reg [1:0] state_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_reg <= ST_LEAK;
        else
            state_reg <= state_next;
    end
    always @(*) begin
        state_next = state_reg;
        // 如果在不應期，或者剛剛spike，下一刻必須是重置狀態
        if (ref_active || post_spike) begin
            state_next = ST_RESET;
        end
        else if (V_next_valid) begin
            // 如果有外部電流輸入，下一刻進入積分狀態
            state_next = ST_INTEGRATE;
        end
        else begin
            // 沒有輸入且不在不應期，進入漏電狀態
            state_next = ST_LEAK;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            V_mem <= {D_WIDTH{1'b0}};
        end else begin
            case (state_next)
                ST_RESET: begin
                    V_mem <= {D_WIDTH{1'b0}}; // 強制歸零
                end
                ST_INTEGRATE: begin
                    V_mem <= V_mem_next;      // 更新積分結果
                end
                ST_LEAK: begin
                    V_mem <= V_mem_leak;      // 更新漏電結果
                end
                default: begin
                    V_mem <= V_mem_leak;
                end
            endcase
        end
    end

    // 漏電單元
    lif_leak #( .D_WIDTH(D_WIDTH), .LEAK_SHIFT(LEAK_SHIFT) ) 
    u_leak (
        .V_in(V_mem),
        .V_leak(V_mem_leak)
    );

    // 積分單元
    lif_integrator #( .D_WIDTH(D_WIDTH) ) 
    u_int (
        .V_leak(V_mem_leak),
        .i_syn(i_syn),
        .V_next(V_mem_next),
        .V_next_valid(V_next_valid)
    );

    // 閾值比較器
    lif_th_cmp #( .D_WIDTH(D_WIDTH), .THRESHOLD(THRESHOLD) ) 
    u_cmp (
        .V_mem(V_mem),
        .spike(post_spike)
    );

    // 不應期控制
    lif_refrac_ctrl #( .REF_PERIOD(REF_PERIOD) ) 
    u_ref (
        .clk(clk),
        .rst_n(rst_n),
        .post_spike(post_spike),
        .ref_active(ref_active)
    );

endmodule
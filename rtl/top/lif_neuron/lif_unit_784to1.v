module lif_unit_784to1 #(
    parameter D_WIDTH    = 8,   // 數據位寬
    parameter I_WIDTH    = 18,  // 電流位寬
    parameter V_WIDTH    = 19,   // 電位位寬
    parameter THRESHOLD  = 800, // 發火閾值
    parameter LEAK_SHIFT = 3,   // 漏電移位
    parameter REF_PERIOD = 3    // 不應期週期數
)(
    input  wire clk,
    input  wire rst_n,
    input  wire accum_en,//啟用訊號
    input  wire [63:0] weight_mem, // 64 個 8 位元權重平坦化輸入
    output wire post_spike
);
    reg  [V_WIDTH-1:0] V_mem;
    wire [V_WIDTH-1:0] V_mem_leak;
    wire [V_WIDTH-1:0] V_mem_next; // 來自積分器的計算結果
    wire V_next_valid;             // 積分器指示是否有效
    wire ref_active;               // 不應期指示信號
    wire [I_WIDTH-1:0] i_syn_group; // 單組權重加總結果
    reg  [I_WIDTH-1:0] i_syn_accum; // 累積 98 組權重加總結果
    reg  [I_WIDTH-1:0] i_syn_hold;  // 暫存輸出給積分器的突觸電流
    reg  [6:0]         weight_grp_cnt;
    reg                i_syn_valid;
    wire [I_WIDTH-1:0] i_syn_to_int; // 輸出給積分器的突觸電流

    localparam ST_LEAK      = 2'b00;
    localparam ST_INTEGRATE = 2'b01;
    localparam ST_RESET     = 2'b10;
    localparam ST_HOLD      = 2'b11;
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
        else if(accum_en && weight_grp_cnt == 7'd0) begin
            // 沒有輸入且不在不應期，進入漏電狀態
            state_next = ST_LEAK;
        end
        else begin
            // 其他情況保持當前狀態
            state_next = ST_HOLD;
        end
    end

    // i_syn 暫存：收集 98 組權重累加後輸出一次
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_syn_accum     <= {I_WIDTH{1'b0}};
            i_syn_hold      <= {I_WIDTH{1'b0}};
            i_syn_valid     <= 1'b0;
            weight_grp_cnt  <= 7'd0;
        end else begin
            if (ref_active || post_spike) begin // 在不應期或剛發火時清除累積值
                i_syn_accum     <= {I_WIDTH{1'b0}};
                i_syn_hold      <= {I_WIDTH{1'b0}};
                i_syn_valid     <= 1'b0;
                weight_grp_cnt  <= 7'd0;
            end else begin
                i_syn_valid <= 1'b0;
                
                // 改為檢查 accum_en
                if (accum_en) begin
                    if (weight_grp_cnt == 7'd97) begin 
                        i_syn_hold     <= i_syn_accum + i_syn_group;
                        i_syn_accum    <= {I_WIDTH{1'b0}};
                        i_syn_valid    <= 1'b1;
                        weight_grp_cnt <= 7'd0;
                    end else begin
                        i_syn_accum    <= i_syn_accum + i_syn_group;
                        weight_grp_cnt <= weight_grp_cnt + 1'b1;
                    end
                end
            end
        end
    end

    // 根據 i_syn_valid 控制是否將 i_syn_hold 傳給積分器
    assign i_syn_to_int = i_syn_valid ? i_syn_hold : {I_WIDTH{1'b0}}; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            V_mem <= {V_WIDTH{1'b0}};
        end else begin
            case (state_next)
                ST_RESET: begin
                    V_mem <= {V_WIDTH{1'b0}}; // 強制歸零
                end
                ST_INTEGRATE: begin
                    V_mem <= V_mem_next;      // 更新積分結果
                end
                ST_LEAK: begin
                    V_mem <= V_mem_leak;      // 更新漏電結果
                end
                ST_HOLD: begin
                    V_mem <= V_mem;           // 保持不變
                end
                default: begin
                    V_mem <= V_mem;           // 預設保持不變
                end
            endcase
        end
    end

    // 加權電流求和單元
    lif_weight_adder #( .D_WIDTH(D_WIDTH), .I_WIDTH(I_WIDTH) )
    u_w_adder (
        .weight_bus(weight_mem),
        .i_syn(i_syn_group)
    );

    // 漏電單元
    lif_leak #( .V_WIDTH(V_WIDTH), .LEAK_SHIFT(LEAK_SHIFT) ) 
    u_leak (
        .V_in(V_mem),
        .V_leak(V_mem_leak)
    );

    // 積分單元
    lif_integrator #( .V_WIDTH(V_WIDTH), .I_WIDTH(I_WIDTH) ) 
    u_int (
        .V_leak(V_mem_leak),
        .i_syn(i_syn_to_int),
        .V_next(V_mem_next),
        .V_next_valid(V_next_valid)
    );

    // 閾值比較器
    lif_th_cmp #( .V_WIDTH(V_WIDTH), .THRESHOLD(THRESHOLD) )
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
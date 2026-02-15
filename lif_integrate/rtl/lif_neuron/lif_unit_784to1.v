module lif_unit_784to1 #(
    parameter D_WIDTH    = 8,
    parameter I_WIDTH    = 18,
    parameter V_WIDTH    = 19,
    parameter THRESHOLD  = 800,
    parameter LEAK_SHIFT = 3,
    parameter REF_PERIOD = 3
)(
    input  wire clk,
    input  wire rst_n,
    input  wire input_valid,      
    input  wire start_of_frame,   
    input  wire [63:0] weight_mem, 
    output wire post_spike,
    output wire sim_step_done, // 修改這裡的邏輯
    output wire [V_WIDTH-1:0] V_mem_out
);

    // ... (前面的宣告保持不變) ...
    reg  [V_WIDTH-1:0] V_mem;
    wire [V_WIDTH-1:0] V_mem_leak;
    wire [V_WIDTH-1:0] V_mem_next;
    wire V_next_valid; 
    wire ref_active;
    wire [I_WIDTH-1:0] i_syn_group;
    reg  [I_WIDTH-1:0] i_syn_accum;
    reg  [I_WIDTH-1:0] i_syn_hold;
    reg  [6:0]         weight_grp_cnt;
    reg                i_syn_valid; 
    wire [I_WIDTH-1:0] i_syn_to_int;

    // [新增] 延遲暫存器，用於對齊 Spike 的時序
    reg sim_step_done_dly;

    // [修正] 輸出延遲後的信號，而不是原始的 i_syn_valid
    assign sim_step_done = sim_step_done_dly;
    
    assign V_mem_out = V_mem;

    // [新增] 延遲邏輯
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sim_step_done_dly <= 1'b0;
        end else begin
            // 將 i_syn_valid 延後一拍輸出
            // 當 LIF 進入 ST_UPDATE (算出新電位) 的當下，sim_step_done 剛好拉高
            sim_step_done_dly <= i_syn_valid;
        end
    end

    // ... (剩下的代碼完全不用動) ...
    // ... 權重累加邏輯 ...
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_syn_accum    <= {I_WIDTH{1'b0}};
            i_syn_hold     <= {I_WIDTH{1'b0}};
            i_syn_valid    <= 1'b0;
            weight_grp_cnt <= 7'd0;
        end else begin
            i_syn_valid <= 1'b0; 
            if (start_of_frame) begin
                 weight_grp_cnt <= 0;
                 i_syn_accum <= 0;
            end
            else if (input_valid) begin 
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
    
    assign i_syn_to_int = i_syn_valid ? i_syn_hold : {I_WIDTH{1'b0}};

    // =======================================================
    // 2. 狀態機與 V_mem 更新 (State Machine)
    // =======================================================
    // 修正：只有在 i_syn_valid (一輪結束) 時才更新 V_mem，避免過度漏電
    
    localparam ST_IDLE      = 2'b00;
    localparam ST_UPDATE    = 2'b01; // 包含 Leak + Integrate
    localparam ST_RESET     = 2'b10;
    
    reg [1:0] state_reg, state_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state_reg <= ST_IDLE;
        else        state_reg <= state_next;
    end

    always @(*) begin
        state_next = state_reg;
        
        // 最高優先級：發火或不應期 -> 重置/保持重置
        if (post_spike || ref_active) begin
            state_next = ST_RESET;
        end
        // 只有當 98 筆累加完成的那一個 Cycle，才進行更新 (Leak + Integrate)
        else if (i_syn_valid) begin
            state_next = ST_UPDATE;
        end
        // 其他時間保持電位不變 (Hold)
        else begin
            state_next = ST_IDLE;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            V_mem <= {V_WIDTH{1'b0}};
        end else begin
            case (state_next)
                ST_RESET: begin
                    V_mem <= {V_WIDTH{1'b0}}; // Hard Reset
                end
                ST_UPDATE: begin
                    // 這裡其實 lif_integrator 已經把 V_leak 和 i_syn 加在一起了
                    // 所以只要 latch 結果即可
                    V_mem <= V_mem_next; 
                end
                ST_IDLE: begin
                    // 保持不變，等待下一次累加完成
                    V_mem <= V_mem; 
                end
            endcase
        end
    end

    // =======================================================
    // 3. 子模組實例化
    // =======================================================
    
    lif_weight_adder #( .D_WIDTH(D_WIDTH), .I_WIDTH(I_WIDTH) )
    u_w_adder (
        .weight_bus(weight_mem),
        .i_syn(i_syn_group)
    );

    // 注意：lif_leak 應該只在 ST_UPDATE 時有效，但組合邏輯隨時都在算，沒關係，我們只在 state 機抓值
    lif_leak #( .V_WIDTH(V_WIDTH), .LEAK_SHIFT(LEAK_SHIFT) ) 
    u_leak (
        .V_in(V_mem),
        .V_leak(V_mem_leak)
    );

    lif_integrator #( .V_WIDTH(V_WIDTH), .I_WIDTH(I_WIDTH) ) 
    u_int (
        .V_leak(V_mem_leak),  // 將 "漏電後的值" 送入積分器
        .i_syn(i_syn_to_int), // 加上 "總電流"
        .V_next(V_mem_next),
        .V_next_valid(V_next_valid)
    );

    lif_th_cmp #( .V_WIDTH(V_WIDTH), .THRESHOLD(THRESHOLD) )
    u_cmp (
        .V_mem(V_mem),
        .spike(post_spike)
    );

    lif_refrac_ctrl #( .REF_PERIOD(REF_PERIOD) ) 
    u_ref (
        .clk(clk),
        .rst_n(rst_n),
        .post_spike(post_spike),
        .ref_active(ref_active)
    );

endmodule
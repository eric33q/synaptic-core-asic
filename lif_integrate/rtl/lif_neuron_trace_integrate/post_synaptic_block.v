module post_synaptic_block #(
    // =======================================================
    // LIF Neuron 參數
    // =======================================================
    parameter D_WIDTH    = 8,
    parameter I_WIDTH    = 18,
    parameter V_WIDTH    = 19,
    parameter THRESHOLD  = 800,
    parameter LEAK_SHIFT = 3,
    parameter REF_PERIOD = 3,
    
    // =======================================================
    // Post-Trace 參數
    // =======================================================
    parameter T_WIDTH     = 8,
    parameter DECAY_SHIFT = 2
)(
    input  wire clk,
    input  wire rst_n,
    
    // --- 來自控制器的輸入 ---
    input  wire input_valid,      // 資料有效
    input  wire start_of_frame,   // 強制重置 (新的一張圖)
    input  wire [63:0] weight_mem,// 權重輸入
    
    // --- 輸出給 Layer 3 (STDP) 的介面 ---
    output wire post_spike,       // 發火信號 (觸發 LTP)
    output wire [T_WIDTH-1:0] post_trace, // 遺跡信號 (計算 LTD)
    
    // --- 監控與 Debug 用 ---
    output wire [V_WIDTH-1:0] V_mem_out
);

    // =======================================================
    // 內部連接線 (Interconnects)
    // =======================================================
    wire internal_spike;      // LIF -> Trace (發火通知)
    wire step_sync_pulse;     // LIF -> Trace (時間步結束同步通知)

    // 將內部發火信號直接拉到輸出
    assign post_spike = internal_spike;

    // =======================================================
    // 1. 實例化 LIF Neuron Core (Layer 2)
    // =======================================================
    lif_unit_784to1 #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) u_lif_core (
        .clk(clk),
        .rst_n(rst_n),
        .input_valid(input_valid),
        .start_of_frame(start_of_frame),
        .weight_mem(weight_mem),
        .post_spike(internal_spike),       // 輸出 Spike
        .sim_step_done(step_sync_pulse),   // [關鍵] 輸出同步脈衝
        .V_mem_out(V_mem_out)
    );

    // =======================================================
    // 2. 實例化 Post-Trace Generator
    // =======================================================
    // 注意：因為這是一個單神經元區塊，NUM_POST 固定為 1
    post_trace #(
        .NUM_POST(1), 
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT)
    ) u_trace_gen (
        .clk(clk),
        .rst_n(rst_n),
        .update_en(step_sync_pulse), // [關鍵] 接收同步脈衝，只有在 LIF 更新時才衰減
        .fire_in(internal_spike),    // 接收 Spike，瞬間充能
        .trace_out_flat(post_trace)  // 輸出 Trace 值
    );

endmodule
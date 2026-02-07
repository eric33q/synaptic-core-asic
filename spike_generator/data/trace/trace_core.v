module trace_core #(
    parameter T_WIDTH     = 8,    
    parameter DECAY_SHIFT = 2     // 衰減速度
)(
    // 注意：移除了 clk 和 rst_n，因為這是純組合邏輯
    input  wire                 spike_in,      // 當前是否有脈衝
    input  wire [T_WIDTH-1:0]   trace_old_in,  // [新增] 從記憶體讀出的舊 Trace 值
    output wire [T_WIDTH-1:0]   trace_new_out  // [修改] 算完準備寫回記憶體的新值
);

    wire [T_WIDTH-1:0] decay_val;   
    wire [T_WIDTH-1:0] trace_decayed;    

    // 1. 計算衰減量
    assign decay_val = trace_old_in >> DECAY_SHIFT;

    // 2. 衰減運算 (保留你原本優秀的防卡死邏輯)
    assign trace_decayed = (trace_old_in != 0 && decay_val == 0) ? 
                           (trace_old_in - 1'b1) : (trace_old_in - decay_val);

    // 3. 決定最終輸出 (有 Spike 就充滿，沒 Spike 就衰減)
    assign trace_new_out = (spike_in) ? {T_WIDTH{1'b1}} : trace_decayed;

endmodule
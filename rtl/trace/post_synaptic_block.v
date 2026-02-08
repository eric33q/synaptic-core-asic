module post_synaptic_block #(
    parameter V_WIDTH = 19,    
    parameter T_WIDTH = 8     
)(
    input  wire          clk,
    input  wire          rst_n,
    
    // --- 來自系統的控制訊號 ---
    input  wire          accum_en,      // 接到 LIF 的新埠口
    input  wire [63:0]   weight_mem_in, // 經過 Masking 的權重
    
    // --- 輸出介面 ---
    output wire          spike_out,     // 輸出脈衝
    output wire [63:0]   post_trace_8x  // 輸出給 STDP 的 Trace (8份)
);
    wire        w_post_spike;
    wire [7:0]  w_single_trace;

    lif_unit_784to1 #(
        .V_WIDTH(V_WIDTH)
    ) u_lif_neuron (
        .clk        (clk),
        .rst_n      (rst_n),
        .accum_en   (accum_en),       
        .weight_mem (weight_mem_in),
        .post_spike (w_post_spike),
        .V_mem_out  ()                
    );

    post_trace #(
        .NUM_POST    (1),
        .T_WIDTH     (T_WIDTH),
        .DECAY_SHIFT (2)
    ) u_post_trace (
        .clk            (clk),
        .rst_n          (rst_n),
        .fire_in        (w_post_spike),
        .trace_out_flat (w_single_trace)
    );

    assign spike_out = w_post_spike;
    //8 個像素全部都連到 同一個神經元 (Neuron 0)
    assign post_trace_8x = {8{w_single_trace}}; //將單一的 trace 複製 8 次
endmodule

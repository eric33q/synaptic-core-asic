module post_trace #(
    parameter NUM_POST    = 1,      // 輸出神經元數量
    parameter T_WIDTH     = 8,      
    parameter DECAY_SHIFT = 2       
)(
    input  wire                     clk,
    input  wire                     rst_n,
    
    // [新增] 更新致能信號 (通常接 LIF 的 i_syn_valid 或類似的 Time Step 結束信號)
    input  wire                     update_en, 

    // --- 來自 LIF Layer 的輸入 ---
    input  wire [NUM_POST-1:0]      fire_in,
    
    // --- 輸出給 STDP Weight Update 的介面 ---
    output wire [NUM_POST*T_WIDTH-1:0] trace_out_flat
);

    reg [NUM_POST*T_WIDTH-1:0] trace_regs;
    wire [NUM_POST*T_WIDTH-1:0] w_new_trace_flat; 

    // 這裡的邏輯不用動，trace_core 負責算 "如果更新，下一個值是多少"
    genvar i;
    generate
        for (i = 0; i < NUM_POST; i = i + 1) begin : post_cores
            trace_core #(
                .T_WIDTH(T_WIDTH),
                .DECAY_SHIFT(DECAY_SHIFT)
            ) u_core (
                .spike_in      (fire_in[i]),
                .trace_old_in  (trace_regs[i*T_WIDTH +: T_WIDTH]),
                .trace_new_out (w_new_trace_flat[i*T_WIDTH +: T_WIDTH])
            );
        end
    endgenerate

    // 狀態更新 (Sequential Logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trace_regs <= {(NUM_POST*T_WIDTH){1'b0}};
        end 
        else if (update_en) begin // [修正] 只有在致能時才更新
            trace_regs <= w_new_trace_flat;
        end
        // else 保持原值
    end

    assign trace_out_flat = trace_regs;

endmodule
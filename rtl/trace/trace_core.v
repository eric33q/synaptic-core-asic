module trace_core #(
    parameter T_WIDTH     = 8,    
    parameter DECAY_SHIFT = 2     // 衰減速度
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 update_en, 
    input  wire                 spike_in,  
    output wire [T_WIDTH-1:0]   trace_out  
);
    reg  [T_WIDTH-1:0] trace_reg;   // 目前的 Trace 數值
    wire [T_WIDTH-1:0] decay_val;   // 衰減值   
    wire [T_WIDTH-1:0] trace_decayed;  // 衰減後的 Trace     
    wire [T_WIDTH-1:0] trace_next;     

    // 衰減邏輯
    assign decay_val = trace_reg >> DECAY_SHIFT;
    //防止當數值很小時，右移結果為 0，會導致數值卡住無法歸零
    assign trace_decayed = (trace_reg != 0 && decay_val == 0) ? 
                           (trace_reg - 1'b1) : (trace_reg - decay_val);
    // Spike -> 255, No Spike -> Decay
    assign trace_next = (spike_in) ? {T_WIDTH{1'b1}} : trace_decayed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trace_reg <= {T_WIDTH{1'b0}};
        end else if (update_en) begin 
            trace_reg <= trace_next;
        end
    end

    assign trace_out = trace_reg;

endmodule
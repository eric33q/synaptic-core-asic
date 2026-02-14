module trace_core #(
    parameter T_WIDTH     = 8,    
    parameter DECAY_SHIFT = 2     // 衰減速度
)(
    input  wire                 spike_in,  
    input  wire [T_WIDTH-1:0]   trace_old_in,  // 從記憶體讀出的舊 Trace 值
    output wire [T_WIDTH-1:0]   trace_new_out  
);
    wire [T_WIDTH-1:0] decay_val;   
    wire [T_WIDTH-1:0] trace_decayed;    

    //衰減量
    assign decay_val = trace_old_in >> DECAY_SHIFT;
    //衰減運算
    assign trace_decayed = (trace_old_in != 0 && decay_val == 0) ? 
              
                           (trace_old_in - 1'b1) : (trace_old_in - decay_val);
    assign trace_new_out = (spike_in) ? {T_WIDTH{1'b1}} : trace_decayed;

endmodule
module pre_trace #(
    parameter T_WIDTH     = 8,      
    parameter DECAY_SHIFT = 2,     
    parameter ADD_VAL     = 8'd64,  
    parameter INPUT_NUM   = 64      // 輸入通道數量
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [INPUT_NUM-1:0]     spike_in,     
    //攤平後的 512-bit 匯流排 (64 * 8)
    output wire [INPUT_NUM*T_WIDTH-1:0] trace_out_flat 
);
    //管理輸入層 64 個通道的 Trace (Pre-synaptic Traces)
    genvar i;
    generate
        for (i = 0; i < INPUT_NUM; i = i + 1) begin : GEN_TRACE_ARRAY
            
            trace_core #(
                .T_WIDTH(T_WIDTH),
                .DECAY_SHIFT(DECAY_SHIFT),
                .ADD_VAL(ADD_VAL)
            ) u_core (
                .clk(clk),
                .rst_n(rst_n),
                .spike_in(spike_in[i]), 
                .trace_out(trace_out_flat[ (i+1)*T_WIDTH-1 : i*T_WIDTH ])
            );
            
        end
    endgenerate

endmodule
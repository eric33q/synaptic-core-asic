module trace_core #(
    parameter T_WIDTH     = 8,    
    parameter DECAY_SHIFT = 2,      // 衰減速度
    parameter ADD_VAL     = 8'd64   // 收到 Spike 時增加的幅度
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 spike_in,  
    output wire [T_WIDTH-1:0]   trace_out  
);

    reg  [T_WIDTH-1:0] trace_reg;   // 目前的 Trace 數值
    wire [T_WIDTH-1:0] decay_val;      
    wire [T_WIDTH-1:0] trace_decayed;  
    wire [T_WIDTH:0]   sum_temp;      
    wire [T_WIDTH-1:0] trace_next;     

    assign decay_val = trace_reg >> DECAY_SHIFT;
    assign trace_decayed = trace_reg - decay_val;  //衰減邏輯
    
    assign sum_temp = trace_reg + ADD_VAL;

    // 若有 Spike：使用 sum_temp (若超過 255 則飽和鎖在 255)
    assign trace_next = spike_in ? 
                        ( (sum_temp > {T_WIDTH{1'b1}}) ? {T_WIDTH{1'b1}} : sum_temp[T_WIDTH-1:0] ) : 
                        trace_decayed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trace_reg <= {T_WIDTH{1'b0}};
        end else begin
            trace_reg <= trace_next;
        end
    end

    assign trace_out = trace_reg;

endmodule
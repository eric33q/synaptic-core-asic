module lif_leak #(
    parameter V_WIDTH    = 19,
    parameter LEAK_SHIFT = 3
)(
    input  wire [V_WIDTH-1:0] V_in,
    output wire [V_WIDTH-1:0] V_leak
);
    wire [V_WIDTH-1:0] decay_val;
    assign decay_val = V_in >> LEAK_SHIFT;
    assign V_leak = (V_in >= decay_val) ? (V_in - decay_val) : {V_WIDTH{1'b0}};
endmodule
module lif_leak #(
    parameter D_WIDTH    = 8,
    parameter LEAK_SHIFT = 3
)(
    input  wire [D_WIDTH-1:0] V_in,
    output wire [D_WIDTH-1:0] V_leak
);
    wire [D_WIDTH-1:0] decay_val;
    assign decay_val = V_in >> LEAK_SHIFT;
    assign V_leak = (V_in >= decay_val) ? (V_in - decay_val) : {D_WIDTH{1'b0}};
endmodule
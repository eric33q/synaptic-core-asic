`timescale 1ns/1ps

module lif_leak #(
    parameter D_WIDTH    = 8,
    parameter LEAK_SHIFT = 3
)(
    input  wire [D_WIDTH-1:0] V_in,
    output wire [D_WIDTH-1:0] V_leak
);
    wire [D_WIDTH-1:0] decay_val;
    
    // 右移運算 (相當於除以 2^LEAK_SHIFT)
    assign decay_val = V_in >> LEAK_SHIFT;
    
    // 安全減法：確保不會減到變成負數 (Underflow protection)
    // 雖然數學上 V_in >= (V_in >> k) 恆成立，但這是良好的硬體習慣
    assign V_leak = (V_in >= decay_val) ? (V_in - decay_val) : {D_WIDTH{1'b0}};

endmodule
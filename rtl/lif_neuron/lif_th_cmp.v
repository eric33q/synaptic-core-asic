module lif_th_cmp#(
    parameter DATA_WIDTH = 8
)(V_mem, spike);
    
    input [DATA_WIDTH-1:0] V_mem;
    output reg spike;
    
    localparam [DATA_WIDTH-1:0] V_th = 8'd20;
    
    always @(*)begin
        spike = (V_mem >= V_th) ? 1'b1 : 1'b0;
    end
endmodule
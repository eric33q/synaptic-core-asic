module lif_th_cmp(V_mem, spike);
    
    input [7:0] V_mem
    output reg spike
    
    parameter [7:0] V_th = 8'd20;
    
    always @(*) begin
        spike = (V_mem >= V_th);
    end
endmodule
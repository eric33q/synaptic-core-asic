module lif_integrator(clk, rst_n, V_leak, i_syn, en, V_next, V_next_valid);
    input clk, rst_n, en;
    input [7:0] V_leak;
    input [7:0] i_syn;
    output reg V_next_valid;
    output reg [7:0] V_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            V_next <= 8'd0;
            V_next_valid <= 1'b0;
        end else begin
            V_next <= V_leak + i_syn;
            V_next_valid <= en;
        end
        
    end
endmodule
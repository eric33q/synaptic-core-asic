module lif_leak(clk, rst_n, V_in, V_leak);
    input clk, rst_n;
    input [7:0] V_in;
    output reg [7:0] V_leak;

    wire [7:0] sum = V_in >> 1; // V_in * 0.5
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            V_leak <= 8'd0;
        end 
        else begin
            V_leak <= (sum > 8'd0) ? sum : 8'd0;
        end
    end
endmodule
module lif_refrac_ctrl(clk, rst_n, post_spike, ref);
    input clk, rst_n, post_spike;
    output reg ref;

    localparam integer REFRAC_LEN = 5;

    reg [2:0] refrac_cnt;  // counts remaining refractory cycles

    wire refrac_active = (refrac_cnt != 3'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refrac_cnt <= 3'd0;
            ref        <= 1'b0;
        end else begin
            if (post_spike) begin
                refrac_cnt <= REFRAC_LEN[2:0];
            end 
            else if (refrac_active) begin
                refrac_cnt <= refrac_cnt - 3'd1;
            end

            if (post_spike || refrac_active) begin
                ref       <= 1'b1;
            end else begin
                ref       <= 1'b0;
            end
        end
    end
endmodule

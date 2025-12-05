module lif_refrac_ctrl #(
    parameter REF_PERIOD = 3
)(
    input  wire clk,
    input  wire rst_n,
    input  wire post_spike,
    output wire ref_active
);
    // 計算不應期
    reg [3:0] cnt;
    //spike後才開始數
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 4'd0;
        end else begin
            if (post_spike) begin
                cnt <= REF_PERIOD[3:0];
            end else if (cnt > 0) begin
                cnt <= cnt - 1'b1;
            end
        end
    end
    // 不為0即在不應期ref_active=1
    assign ref_active = (cnt != 4'd0);

endmodule
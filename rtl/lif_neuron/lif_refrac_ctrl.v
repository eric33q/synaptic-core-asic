`timescale 1ns/1ps
module lif_refrac_ctrl #(
    parameter REF_PERIOD = 3
)(
    input  wire clk,
    input  wire rst_n,
    input  wire post_spike,
    output wire ref_active
);
    // 計算不應期
    // 自動計算計數器所需的位寬，以容納 REF_PERIOD
    localparam CNT_WIDTH = (REF_PERIOD == 0) ? 1 : $clog2(REF_PERIOD + 1);
    reg [CNT_WIDTH-1:0] cnt;
    //spike後才開始數
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else begin
            if (post_spike) begin
                cnt <= REF_PERIOD;
            end else if (cnt > 0) begin
                cnt <= cnt - 1'b1;
            end
        end
    end
    // 不為0即在不應期ref_active=1
    assign ref_active = (cnt != 0);

endmodule

`timescale 1ns/1ps

module lif_refrac_logic #(
    parameter REF_WIDTH  = 4,
    parameter REF_PERIOD = 3
)(
    input  wire [REF_WIDTH-1:0] cnt_old,
    input  wire                 post_spike, // 必須來自 masked spike
    output reg  [REF_WIDTH-1:0] cnt_new,
    output wire                 ref_active  // 關鍵訊號
);

    // 關鍵檢查：cnt_old 不為 0 時，ref_active 必須為 1
    // 如果這裡寫錯 (例如寫成 == 0)，就會導致死鎖
    assign ref_active = (cnt_old != {REF_WIDTH{1'b0}});

    always @(*) begin
        if (post_spike) begin
            // 剛發火，重置計數器
            cnt_new = REF_PERIOD[REF_WIDTH-1:0];
        end 
        else if (ref_active) begin
            // 不應期中，倒數
            cnt_new = cnt_old - 1'b1;
        end 
        else begin
            // 閒置
            cnt_new = {REF_WIDTH{1'b0}};
        end
    end
endmodule
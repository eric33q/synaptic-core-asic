`timescale 1ns/1ps

module lif_refrac_logic #(
    parameter REF_WIDTH  = 4,
    parameter REF_PERIOD = 3
)(
    input  wire [REF_WIDTH-1:0] cnt_old,    // 來自 SRAM 的舊計數
    input  wire post_spike,                 // 當下是否發火 (來自比較器)
    output reg  [REF_WIDTH-1:0] cnt_new,    // 寫回 SRAM 的新計數
    output wire ref_active                  // 輸出：是否在不應期
);

    // 只要計數器不為 0，就代表處於不應期
    assign ref_active = (cnt_old != {REF_WIDTH{1'b0}});

    always @(*) begin
        if (post_spike) begin
            // 剛發火，重置不應期計數器 (設為最大值)
            cnt_new = REF_PERIOD[REF_WIDTH-1:0];
        end 
        else if (ref_active) begin
            // 正在倒數中，計數減 1
            cnt_new = cnt_old - 1'b1;
        end 
        else begin
            // 閒置狀態 (非不應期)
            cnt_new = {REF_WIDTH{1'b0}};
        end
    end

endmodule
`timescale 1ns/1ps

module lif_refrac_logic #(
    parameter REF_WIDTH  = 4,
    parameter REF_PERIOD = 3
)(
    input  wire [REF_WIDTH-1:0] cnt_old,
    input  wire                 spike_out,
    output reg  [REF_WIDTH-1:0] cnt_new,
    output wire                 ref_active
);
    assign ref_active = (cnt_old != {REF_WIDTH{1'b0}});
    always @(*) begin
        if (spike_out) begin
            cnt_new = REF_PERIOD[REF_WIDTH-1:0];
        end 
        else if (ref_active) begin
            cnt_new = cnt_old - 1'b1;
        end 
        else begin
            cnt_new = {REF_WIDTH{1'b0}};
        end
    end
endmodule
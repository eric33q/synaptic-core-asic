`timescale 1ns/1ps

module top #(
    parameter D_WIDTH   = 8,
    parameter BATCH_NUM = 98
)(
    input  wire clk,
    input  wire rst_n,
    input  wire test_mode,
    input  wire start,
    input wire accumulate_en,
    input  wire [15:0] data_in,
    output wire [7:0]  spike_data, 
    output wire        valid,
    output wire        busy,
    output wire        done 
);
    wire [6:0] cur_batch_cnt;
    reg [63:0] pixel_data_in;
    reg [1:0] data_cnt;
    reg pixel_valid_in;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data_in  <= 64'd0;
            data_cnt       <= 2'd0;
            pixel_valid_in <= 1'b0;
        end
        else if (start) begin
            pixel_data_in  <= 64'd0;
            data_cnt       <= 2'd0;
            pixel_valid_in <= 1'b0;
        end
        else begin
            pixel_data_in <= {data_in[15:0], pixel_data_in[63:16]};
            data_cnt <= data_cnt + 2'd1;
            pixel_valid_in <= (data_cnt == 2'd3)? 1'b1 : 1'b0;   
        end
    end
    spike_generator #(
        .D_WIDTH   (D_WIDTH),
        .BATCH_NUM (BATCH_NUM)
    ) u_generator (
        .clk            (clk),
        .rst_n          (rst_n),
        .test_mode      (test_mode),
        .start          (start),
        .accumulate_en  (accumulate_en),
        .pixel_valid_in (pixel_valid_in),
        .busy           (busy),
        .finish         (done),     
        .pixel_data_in  (pixel_data_in),
        .cur_batch_cnt  (cur_batch_cnt),
        .spike_data_out (spike_data),
        .spike_valid    (valid)
    );
    
endmodule
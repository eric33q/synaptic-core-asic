`timescale 1ns/1ps

module layer1_system_top #(
    // 將參數提取到頂層，增加重用性
    parameter D_WIDTH   = 8,
    parameter BATCH_NUM = 98
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input wire accumulate_en,
    input wire pixel_valid_in, // 新增
    // --- 輸入：像素數據 ---
    input  wire [63:0] pixel_data_in,
    output wire [6:0]  cur_batch_cnt,
    
    // --- 輸出：給 Layer 2 的介面 ---
    output wire [7:0]  L2_spike_data, 
    output wire        L2_valid,
    
    // --- 狀態輸出 ---
    output wire        L1_busy,
    output wire        L1_done 
);

    // 直接實例化，不需要定義中間 wire 和 assign
    spike_generator #(
        .D_WIDTH   (D_WIDTH),
        .BATCH_NUM (BATCH_NUM)
    ) u_generator (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .accumulate_en  (accumulate_en),
        .pixel_valid_in (pixel_valid_in),
        // 直接將頂層 Output 連接到子模組 Output
        .busy           (L1_busy),
        .finish         (L1_done),     
        
        .pixel_data_in  (pixel_data_in),
        .cur_batch_cnt       (cur_batch_cnt),
        
        .spike_data_out (L2_spike_data),
        .spike_valid    (L2_valid)
    );
    
endmodule
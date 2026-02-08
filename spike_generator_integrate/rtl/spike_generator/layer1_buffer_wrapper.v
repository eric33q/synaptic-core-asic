`timescale 1ns/1ps

module layer1_buffer_wrapper #(
    parameter D_WIDTH    = 8,
    parameter BATCH_NUM  = 98,
    parameter TOTAL_PIXELS = 784
)(
    input  wire clk,
    input  wire rst_n,
    
    // --- 系統控制 ---
    input  wire start,          // 開始運算訊號
    input  wire accumulate_en,  // 是否累積電位
    input  wire l2_done_ack,    // [新] 來自 Layer 2 的訊號：告訴 Buffer "我讀完了，你可以清空了"
    
    // --- 數據輸入 (外部記憶體介面) ---
    input  wire [63:0] pixel_data_in,
    output wire [6:0]  req_addr,
    
    // --- 系統狀態輸出 ---
    output wire l1_busy,
    output wire l1_finish,
    
    // --- 給 Layer 2 的核心輸出 (784 bits) ---
    output wire [TOTAL_PIXELS-1:0] L2_input_vector, // 完整的 784-bit 向量
    output wire                    L2_input_valid   // 當這個為 1，代表 L2_input_vector 數據有效
);

    // =======================================================
    // 內部連接線 (Wires) - 這就是「電線」
    // =======================================================
    wire [7:0] w_spike_data_8bit; // 連接 L1 輸出 -> Buffer 輸入
    wire       w_spike_valid;     // 連接 L1 Valid -> Buffer Valid
    wire       w_buf_ready;       // Buffer 告訴 L1 它準備好了 (目前 L1 沒用到這個，但預留著)

    // =======================================================
    // 1. 實例化 Layer 1 (Spike Generator)
    // =======================================================
    spike_generator #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM)
    ) u_layer1 (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .accumulate_en (accumulate_en),
        .busy          (l1_busy),
        .finish        (l1_finish),
        
        .pixel_data_in (pixel_data_in),
        .req_addr      (req_addr),
        
        // [關鍵連接點] 這裡輸出給內部電線
        .spike_data_out(w_spike_data_8bit), 
        .spike_valid   (w_spike_valid)
    );

    // =======================================================
    // 2. 實例化 Buffer (Serial to Parallel)
    // =======================================================
    spike_buffer_layer1 #(
        .INPUT_WIDTH (8),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) u_buffer (
        .clk   (clk),
        .rst_n (rst_n),

        // [關鍵連接點] 這裡接收內部電線的數據
        .l1_spike_data (w_spike_data_8bit),
        .l1_valid      (w_spike_valid),
        .buf_ready     (w_buf_ready), // 輸出給內部，雖然 L1 目前沒在看

        // [對外輸出] 這裡直接連到 Top 的 Output 給 Layer 2
        .l2_full_spike_vector (L2_input_vector),
        .l2_valid             (L2_input_valid),
        .l2_done              (l2_done_ack) // 這是外部輸入，模擬 Layer 2 說 "OK"
    );

endmodule
`timescale 1ns/1ps

module system_tb;

    // ==========================================
    // 1. 參數設定
    // ==========================================
    parameter D_WIDTH    = 8;
    parameter T_WIDTH    = 8;      // Trace 位寬
    parameter DECAY_SHIFT= 2;
    parameter INPUT_NUM  = 784;    // MNIST 28x28
    parameter BATCH_SIZE = 8;
    parameter BATCH_NUM  = 98;     // 784 / 8

    // ==========================================
    // 2. 訊號宣告
    // ==========================================
    reg clk;
    reg rst_n;
    reg start;
    
    // Layer 1 的輸出訊號
    wire busy;
    wire finish;
    wire [6:0] req_addr;       // 硬體請求的 Batch 地址 (0~97)
    wire [7:0] spike_data;     // Layer 1 吐出的 Spike (8-bit)
    wire spike_valid;
    
    // ROM 模擬訊號
    wire [63:0] pixel_in;      // 餵給 Layer 1 的像素數據
    reg  [63:0] img_rom [0:97];// 模擬記憶體 (存放 Hex 檔)

    //  Pre-Trace 最終輸出 (784 * 8 bits)
    wire [INPUT_NUM*T_WIDTH-1:0] final_traces;

    // 用於波形觀察的輔助訊號 (只拉出前幾個 Pixel 看有沒有反應)
    wire [T_WIDTH-1:0] trace_pixel_0;  // Pixel 0 的 Trace
    wire [T_WIDTH-1:0] trace_pixel_1;  // Pixel 1 的 Trace
    wire [T_WIDTH-1:0] trace_pixel_232;// Pixel 232 的 Trace (中間區域)

    // 從巨大的匯流排中切出我們想看的
    assign trace_pixel_0   = final_traces[1*T_WIDTH-1 : 0*T_WIDTH];
    assign trace_pixel_1   = final_traces[2*T_WIDTH-1 : 1*T_WIDTH];
    assign trace_pixel_232 = final_traces[233*T_WIDTH-1 : 232*T_WIDTH];
    // ==========================================
    // 3. 實例化 Layer 1 
    // ==========================================
    lif_layer1_top #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM)
    ) u_layer1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .finish(finish),             // 接到 pre_trace 的 cmd_finish
        .pixel_data_in(pixel_in),    // 接到下方的 ROM 邏輯
        .req_addr(req_addr),         // 接到下方的 ROM 邏輯
        .spike_data_out(spike_data), // 接到 pre_trace
        .spike_valid(spike_valid)    // 接到 pre_trace
    );

    // ==========================================
    // 4. 實例化 Pre-Trace 
    // ==========================================
    pre_trace #(
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT),
        .INPUT_NUM(INPUT_NUM),
        .BATCH_SIZE(BATCH_SIZE)
    ) u_trace (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_start(start),           // Start 同步清空 Buffer
        .cmd_finish(finish),         // Finish 觸發 Trace 更新 (Decay/Fire)
        .serial_spike_in(spike_data),// 接收 8-bit 脈衝流
        .batch_addr(req_addr),       // 知道現在是哪一批
        .spike_valid(spike_valid),   // 資料有效才收
        .STDP_trace_out(final_traces)// 最終 784 個 Trace
    );

    // ==========================================
    // 5. ROM 資料餵食邏輯
    // ==========================================
    // 當 Layer 1 處於 Busy 狀態並送出地址時，馬上給出數據
    assign pixel_in = (busy) ? img_rom[req_addr] : 64'd0;

    // ==========================================
    // 6. 時脈產生
    // ==========================================
    always #5 clk = ~clk; // 100MHz

    // ==========================================
    // 7. 測試流程
    // ==========================================
    integer k; // 宣告迴圈變數
    integer t;
    initial begin
        // 設定波形輸出
        $fsdbDumpfile("system_integration.fsdb");
        $fsdbDumpvars(0, system_tb, "+all");

        // 初始化訊號
        clk = 0;
        rst_n = 0;
        start = 0;

        // 載入圖片數據
        $readmemh("mnist_input.hex", img_rom);
        
        // ========================================================
        // 強制初始化 Layer 1 內部的 SRAM
        // ========================================================
        $display("--- Force Initializing Layer 1 SRAM ---");
        for (k = 0; k < 98; k = k + 1) begin
            // 透過路徑直接存取內部變數： u_layer1 是實例化名稱，state_sram 是內部變數
            u_layer1.state_sram[k] = 96'd0; 
        end
        // ========================================================

        // 系統重置
        #20 rst_n = 1;
        #20;

        $display("=== Simulation Start ===");
        

        // --- 模擬多個 Time Steps (處理同一張圖多次，觀察積分與 Trace 變化) ---
        for (t = 1; t <= 5; t = t + 1) begin
            $display("\n[Time Step %0d] Processing Image...", t);
            
            // 1. 發送 Start 脈衝
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            // 2. 等待 Layer 1 處理完這張圖 (98 cycles)
            // 當 finish 拉高時，Layer 1 結束，Trace 同步更新
            wait(finish == 1);
            
            // 3. 顯示更新後的 Trace 數值 (只顯示部分像素)
            // 延遲一點點確保數值已穩定寫入
            #1; 
            $display("   -> Finish Signal Detected. Trace Updated.");
            $display("   -> Pixel 0 Trace:   %3d", trace_pixel_0);
            $display("   -> Pixel 232 Trace: %3d", trace_pixel_232);
            
            // 等待一下再進入下一個 Time Step
            @(posedge clk);
            @(posedge clk);
        end

        $display("\n=== Simulation Done ===");
        $finish;
    end

endmodule


`timescale 1ns/1ps

module layer1_buffer_wrapper_tb;

    // =======================================================
    // 1. 參數定義
    // =======================================================
    parameter CLK_PERIOD   = 10;
    parameter D_WIDTH      = 8;
    parameter BATCH_NUM    = 98;
    parameter TOTAL_PIXELS = 784;

    // =======================================================
    // 2. 訊號宣告
    // =======================================================
    reg  clk;
    reg  rst_n;
    
    // 系統控制訊號
    reg  start;
    reg  accumulate_en;
    reg  l2_done_ack;      // 模擬 Layer 2 回傳的 "算完了" 訊號

    // 記憶體介面
    reg  [63:0] pixel_data_in;
    wire [6:0]  req_addr;

    // 輸出觀察
    wire l1_busy;
    wire l1_finish;
    wire [TOTAL_PIXELS-1:0] L2_input_vector; // 784 bits 的大向量
    wire                    L2_input_valid;  // Buffer 滿載指示燈

    // 模擬用記憶體 (存放圖片)
    reg [63:0] image_rom [0:BATCH_NUM-1];

    // =======================================================
    // 3. 實例化 DUT (Device Under Test)
    // =======================================================
    layer1_buffer_wrapper #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) u_dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (start),
        .accumulate_en   (accumulate_en),
        .l2_done_ack     (l2_done_ack),  // [握手] 輸入
        .pixel_data_in   (pixel_data_in),
        .req_addr        (req_addr),
        .l1_busy         (l1_busy),
        .l1_finish       (l1_finish),
        .L2_input_vector (L2_input_vector), // [資料] 輸出
        .L2_input_valid  (L2_input_valid)   // [握手] 輸出
    );

    // =======================================================
    // 4. 時脈與記憶體模擬
    // =======================================================
    // 產生時脈
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // 模擬外部記憶體行為 (SRAM Read Latency = 1 cycle)
    always @(posedge clk) begin
        if (!rst_n) 
            pixel_data_in <= 0;
        else 
            pixel_data_in <= image_rom[req_addr];
    end

    // =======================================================
    // 5. 波形紀錄 (FSDB/VCD)
    // =======================================================
    initial begin
        $fsdbDumpfile("layer1_buffer_wrapper.fsdb");
        $fsdbDumpvars(0, layer1_buffer_wrapper_tb, "+mda");
        // 如果想看 784 bits 的大向量，記得加 +mda
        // $fsdbDumpvars(0, tb_layer1_buffer_wrapper, "+mda"); 
    end

    // =======================================================
    // 6. 測試流程 (Test Scenario)
    // =======================================================
    integer epoch;
    
    initial begin
        // --- 初始化 ---
        $display("=== Simulation Start ===");
        
        // 1. 載入圖片 (請確保目錄下有這個檔案)
        // 這裡假設檔案裡剛好有 98 行 hex 數據
        $readmemh("mnist_input.hex", image_rom);

        // 2. 重置系統
        rst_n = 1; start = 0; accumulate_en = 0; l2_done_ack = 0;
        #(CLK_PERIOD*2); rst_n = 0; 
        #(CLK_PERIOD*2); rst_n = 1;
        #(CLK_PERIOD*5);

        // --- 開始訓練迴圈 (模擬跑 3 個 Epochs) ---
        for (epoch = 1; epoch <= 3; epoch = epoch + 1) begin
            
            $display("\n--- Epoch %0d Start ---", epoch);

            // 設定累積模式：第一個 epoch 清空，之後累積
            if (epoch == 1) accumulate_en = 0;
            else            accumulate_en = 1;

            // 3. 發送 Start 脈衝
            @(posedge clk); start = 1;
            @(posedge clk); start = 0;
            
            // 4. 等待 Buffer 收集滿 784 bits
            // 這裡我們會一直等，直到 L2_input_valid 變為 1
            wait(L2_input_valid == 1);
            
            $display("[Time %t] Buffer Full! Valid signal received.", $time);
            
            // (驗證點) 可以在這裡檢查 L2_input_vector 的內容
            // 例如檢查第 0 個 bit 是否有脈衝
            // if (L2_input_vector[0] == 1) $display("  Pixel 0 Fired!");

            // 5. 模擬 Layer 2 的運算時間
            // 假設 Layer 2 讀取這 784 bits 並更新權重需要花 10 個 cycles
            repeat(10) @(posedge clk);

            // 6. 發送 Handshake ACK (我算完了，你可以清空了)
            $display("[Time %t] Layer 2 finishes calculation. Sending ACK.", $time);
            l2_done_ack = 1;
            @(posedge clk); 
            l2_done_ack = 0;

            // 7. 確認 Valid 訊號是否被拉低 (Buffer 應該要解鎖)
            @(posedge clk);
            if (L2_input_valid == 0)
                $display("[Time %t] Handshake Success. Buffer cleared.", $time);
            else
                $display("[Error] Buffer did not clear valid signal!");

            // 休息一下，準備下一個 Epoch
            #(CLK_PERIOD*20);
        end

        $display("\n=== Simulation Finished Successfully ===");
        $finish;
    end

endmodule
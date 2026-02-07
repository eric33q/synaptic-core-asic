`timescale 1ns/1ps

module layer1_trace_integration_tb;

    // =======================================================
    // 1. 參數定義
    // =======================================================
    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98;
    parameter T_WIDTH    = 8;

    // =======================================================
    // 2. 訊號宣告
    // =======================================================
    reg  clk;
    reg  rst_n;
    reg  start;
    reg  accumulate_en;

    // 模擬外部 Image ROM
    reg  [63:0] pixel_data_in;
    wire [6:0]  req_addr;

    // 觀察輸出 (DUT Outputs)
    wire L1_busy;
    wire L1_done;
    wire [D_WIDTH-1:0]               spike_data_out;  // 8 bits
    wire                             spike_valid_out;       // 1 bit
    wire [D_WIDTH*T_WIDTH-1:0]       trace_data_out; // 64 bits

    // 模擬用記憶體 (存放圖片)
    // 寬度 64 bits，深度 98
    reg [63:0] test_image_rom [0:97];

    // =======================================================
    // 3. 實例化 DUT (L1_Trace_Group)
    // =======================================================
    layer1_trace_integration #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM),
        .T_WIDTH(T_WIDTH)
    ) u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .accumulate_en  (accumulate_en),
        
        // Image ROM 介面
        .pixel_data_in  (pixel_data_in),
        .req_addr       (req_addr),
        
        // 狀態
        .L1_busy        (L1_busy),
        .L1_done        (L1_done),
        
        // 核心輸出
        .spike_data_out  (spike_data_out),
        .spike_valid_out (spike_valid_out),
        .trace_data_out (trace_data_out)
    );
    initial begin
        $fsdbDumpfile("layer1_trace_integration.fsdb");
        $fsdbDumpvars(0, layer1_trace_integration_tb, "+mda");
    end
    // =======================================================
    // 4. 時脈與 ROM 行為
    // =======================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // 模擬同步 ROM 讀取 (1 cycle latency)
    always @(posedge clk) begin
        pixel_data_in <= test_image_rom[req_addr];
    end

    // =======================================================
    // 5. 測試流程 (Test Scenario) - 跑 5 個 Epochs
    // =======================================================
    integer epoch; // 定義迴圈變數
    
    initial begin
        // --- 1. 載入檔案 ---
        $display("Loading image file: mnist_input.hex.txt ...");
        $readmemh("mnist_input.hex", test_image_rom);

        // 檢查 ROM 是否載入成功
        #1;
        if (test_image_rom[0] === 64'bx) begin
            $display("[Error] ROM Load Failed! Please check file path.");
            $finish;
        end else begin
            $display("[Success] ROM Loaded. Addr[0] = %h", test_image_rom[0]);
        end

        // --- 2. 系統重置 ---
        $display("=== Simulation Start (Target: 5 Epochs) ===");
        rst_n = 1; start = 0; accumulate_en = 0;
        #(CLK_PERIOD*2); rst_n = 0; 
        #(CLK_PERIOD*2); rst_n = 1;
        #(CLK_PERIOD*5);

        // --- 3. 開始 5 個 Epoch 的迴圈 ---
        for (epoch = 1; epoch <= 5; epoch = epoch + 1) begin
            
            $display("\n--- Epoch %0d Start ---", epoch);
            
            // [策略設定]
            // Epoch 1: 關閉累積 (accumulate_en=0)，讓神經元電位重置/初始化
            // Epoch 2~5: 開啟累積 (accumulate_en=1)，模擬連續時間步的電位累積
            if (epoch == 1) accumulate_en = 0;
            else            accumulate_en = 1;

            // 發送 Start 脈衝
            @(posedge clk); start = 1;
            @(posedge clk); start = 0;

            // 等待這一張圖處理完畢
            wait(L1_done);
            
            // 休息一下，讓波形在兩次 Epoch 之間有點間隔，方便觀察
            #(CLK_PERIOD*20);
        end
        
        $display("\n=== Simulation Finished: 5 Epochs Completed ===");
        $finish;
    end

    // =======================================================
    // 6. 監控輸出 (Log Monitor) - 包含正確的地址計數
    // =======================================================
    integer monitor_addr_cnt; // Testbench 專用的地址計數器

    // 計數器邏輯
    always @(posedge clk) begin
        if (!rst_n) begin
            monitor_addr_cnt <= 0;
        end
        else if (start) begin
            // 每個 Epoch 開始時 (收到 start)，計數器歸零
            monitor_addr_cnt <= 0;
        end
        else if (spike_valid_out) begin
            // 每輸出一筆有效資料，計數器 + 1
            monitor_addr_cnt <= monitor_addr_cnt + 1;
        end
    end

    // 顯示邏輯
    always @(posedge clk) begin
        if (spike_valid_out) begin
            // 使用 monitor_addr_cnt 顯示當前地址，確保與數據同步
            $display("Epoch %0d | Time %t | Addr: %2d | Spike: %b | Trace[0]: %3d | Trace[1]: %3d", 
                     epoch, $time, monitor_addr_cnt, spike_data_out, trace_data_out[7:0], trace_data_out[15:8]);
        end
    end

endmodule
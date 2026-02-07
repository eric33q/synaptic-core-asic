`timescale 1ns/1ps

module spike_generator_tb;

    // ==========================================
    // 1. 參數設定 (必須與 RTL 一致)
    // ==========================================
    parameter D_WIDTH    = 8;
    parameter REF_WIDTH  = 4;
    parameter THRESHOLD  = 50;  // 注意：因為真實圖片轉換後數值較小，我們先把閾值調低一點以便觀察發火
                                // 或者你可以保持 200，但要確保輸入數值夠大
    parameter LEAK_SHIFT = 3;
    parameter REF_PERIOD = 3;
    parameter BATCH_NUM  = 98;  // 784 / 8 = 98

    // ==========================================
    // 2. 訊號宣告
    // ==========================================
    reg clk;
    reg rst_n;
    reg start;
    
    // DUT (Device Under Test) 的輸出
    wire busy;
    wire finish;
    wire [6:0] req_addr;       // 硬體跟我們要第幾號批次的資料
    wire [7:0] spike_data_out; // 硬體輸出的脈衝
    wire spike_valid;

    // DUT 的輸入
    wire [63:0] pixel_data_in; // 我們餵給硬體的資料

    // ==========================================
    // 3. 模擬記憶體 (ROM)
    // ==========================================
    // 存放從 Python 轉出來的 hex 檔
    reg [63:0] img_rom [0:97]; 

    // ==========================================
    // 4. 實例化 Layer 1 Top Module
    // ==========================================
    spike_generator #(
        .D_WIDTH(D_WIDTH),
        .REF_WIDTH(REF_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD),
        .BATCH_NUM(BATCH_NUM)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .finish(finish),
        .pixel_data_in(pixel_data_in), // 接到下面的 assign
        .req_addr(req_addr),
        .spike_data_out(spike_data_out),
        .spike_valid(spike_valid)
    );
    initial
    begin
        // 指定波形檔名
        $fsdbDumpfile("spike_generator.fsdb");
        // 0 代表記錄所有層級，one_to_one_tb 代表從 Testbench 頂層開始抓
        // "+all" 確保抓取所有訊號類型 (包含 memory array 等)
        $fsdbDumpvars(0, spike_generator_tb, "+all");
    end
    // ==========================================
    // 5. 時脈產生 (100MHz, 週期 10ns)
    // ==========================================
    always #5 clk = ~clk;

    // ==========================================
    // 6. 關鍵：資料餵食邏輯
    // ==========================================
    // 這裡使用 assign 組合邏輯，模擬「零延遲」的 SRAM/ROM 讀取。
    // 當硬體送出 req_addr 的當下，pixel_data_in 馬上準備好。
    // 這配合了硬體內部的 Read-Modify-Write 單週期架構。
    assign pixel_data_in = (busy) ? img_rom[req_addr] : 64'd0;

    // ==========================================
    // 7. 模擬流程控制
    // ==========================================
    integer t; // Time Step 計數
    integer i;
    
    initial begin
        // --- 初始化 ---
        clk = 0;
        rst_n = 0;
        start = 0;
        
        // --- 載入 Hex 檔 ---
        $display("==================================================");
        $display(" Loading MNIST Data: mnist_input.hex");
        $display("==================================================");
        // 請確保 mnist_input.hex 和這個 .v 檔在同一目錄，或填寫絕對路徑
        $readmemh("mnist_input.hex", img_rom);

        // 檢查一下頭尾有沒有讀進去 (除錯用)
        #1;
        $display("Debug: ROM[0]  = %h", img_rom[0]);
        $display("Debug: ROM[97] = %h", img_rom[97]);

        // --- Reset ---
        #20 rst_n = 1;
        #20;

        // --- 開始模擬 SNN 運作 ---
        // 我們讓它跑 20 個 Time Steps，觀察積分與發火過程
        for (t = 1; t <= 20; t = t + 1) begin
            $display("\n--- Time Step %0d Start ---", t);
            
            // 1. 發送 Start 脈衝 (一個 Clock)
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // 2. 等待這一張圖處理完 (Finish 訊號)
            wait(finish == 1);
            
            // 3. 稍微等一下再進下一個 Time Step
            @(posedge clk); 
        end
        
        $display("\n==================================================");
        $display(" Simulation Done!");
        $display("==================================================");
        $stop;
    end

    // ==========================================
    // 8. 觀察輸出 (Monitor)
    // ==========================================
    // 當有 Spike 產生時，印出來
    always @(posedge clk) begin
        if (spike_valid && spike_data_out != 8'd0) begin
            // 印出：時間 | Batch編號 | 脈衝二進位 | 這些脈衝對應的原始像素區間
            // 這可以幫你對照原圖，看是不是在筆畫的地方發火
            $display("[Time %t] Spike Fired! Batch: %2d | Spikes: %b (Pixels %3d-%3d)", 
                     $time, req_addr, spike_data_out, req_addr*8+7, req_addr*8);
        end
    end

endmodule
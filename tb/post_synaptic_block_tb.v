`timescale 1ns/1ps

module post_synaptic_block_tb;

    // --- 參數設定 ---
    parameter V_WIDTH = 19;
    parameter T_WIDTH = 8;
    parameter CLK_PERIOD = 10; 

    // --- 訊號宣告 ---
    reg          clk;
    reg          rst_n;
    reg          accum_en;
    reg          update_en;     // 對應 post_trace 的鎖存控制
    reg  [63:0]  weight_mem_in;
    
    wire         spike_out;
    wire [63:0]  post_trace_8x;

    // --- 待測物 (DUT) 實例化 ---
    post_synaptic_block #(
        .V_WIDTH(V_WIDTH),
        .T_WIDTH(T_WIDTH)
    ) u_dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .accum_en      (accum_en),
        .update_en     (update_en),     
        .weight_mem_in (weight_mem_in),
        .spike_out     (spike_out),
        .post_trace_8x (post_trace_8x)
    );

    // --- 時脈產生 ---
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- 測試流程 ---
    initial begin
        // 1. 初始化
        clk = 0;
        rst_n = 1;
        accum_en = 0;
        update_en = 0;
        weight_mem_in = 64'd0;
        
        $display("=== Simulation Start ===");
        
        // 2. 系統重置
        #(CLK_PERIOD * 2);
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // -------------------------------------------------------
        // 測試情境 1: 積分 98 個 Cycle 並強迫發火
        // -------------------------------------------------------
        $display("Test 1: Accumulating 98 cycles & Force Firing...");
        
        @(negedge clk);
        weight_mem_in = {8{8'hFF}}; 
        accum_en = 1;      // 開始積分
        update_en = 0;     // 掃描期間不更新 Trace 

        // 模擬掃描過程
        repeat(97) @(posedge clk);
        
        // 第 98 個週期檢查是否發火
        wait(spike_out == 1);
        $display("  -> Spike Detected at time %t!", $time);
        
        // 關鍵：第 99 個週期觸發 Trace 更新 (Update Phase)
        @(negedge clk);
        accum_en = 0;      // 停止積分
        update_en = 1;     // 觸發更新脈衝，讓 Trace 讀取發火狀態
        
        @(posedge clk);    // 採樣更新
        #1;
        update_en = 0;     // 關閉更新 (鎖存)

        if (post_trace_8x[7:0] == 255) 
            $display("  -> Trace Check PASS: Trace reset to 255 (LTP).");
        else
            $display("  -> Trace Check FAIL: Trace is %d (Expected 255).", post_trace_8x[7:0]);

        // -------------------------------------------------------
        // 測試情境 2: 觀察 Trace 鎖存與衰減
        // -------------------------------------------------------
        $display("Test 2: Checking Trace Hold & Decay...");
        
        // A. 驗證鎖存：即使過了 10 個週期，只要 update_en=0，Trace 應維持 255
        repeat(10) @(posedge clk);
        if (post_trace_8x[7:0] == 255)
            $display("  -> Hold Check PASS: Trace remained 255 during scanning.");
        else
            $display("  -> Hold Check FAIL: Trace changed without update_en!");

        // B. 執行衰減更新 (LTD)
        @(negedge clk);
        update_en = 1;     // 觸發衰減更新
        
        @(posedge clk);
        #1;
        update_en = 0;     // 再次鎖存

        if (post_trace_8x[7:0] == 192) // 255 - (255 >> 2) = 192
            $display("  -> Decay Check PASS: Trace decayed to 192.");
        else
            $display("  -> Decay Check FAIL: Trace is %d (Expected 192).", post_trace_8x[7:0]);

        // -------------------------------------------------------
        // 測試結束
        // -------------------------------------------------------
        #(CLK_PERIOD * 10);
        $display("=== Simulation Done ===");
        $finish;
    end

    // 產生波形檔
    initial begin
        $fsdbDumpfile("post_synaptic_block_tb.fsdb");
        $fsdbDumpvars(0, post_synaptic_block_tb, "+all");
    end

endmodule

`timescale 1ns/1ps

module pre_trace_tb;

    // =======================================================
    // 1. 參數與訊號宣告
    // =======================================================
    parameter CLK_PERIOD = 10;
    parameter T_WIDTH    = 8;
    parameter BATCH_NUM  = 98;
    parameter N_PARALLEL = 8;
    parameter ADDR_WIDTH = 7;

    reg                     clk;
    reg                     rst_n;
    
    // 輸入
    reg                     update_en;
    reg  [ADDR_WIDTH-1:0]   addr_in;
    reg  [N_PARALLEL-1:0]   spikes_in; // 8-bit 輸入 (例如 8'b00000001)

    // 輸出
    wire [N_PARALLEL*T_WIDTH-1:0] trace_out_flat;

    // 輔助觀察用的 Wire (把攤平的訊號切開比較好觀察)
    wire [7:0] debug_trace_0 = trace_out_flat[7:0];   // 第 0 顆像素的 Trace
    wire [7:0] debug_trace_1 = trace_out_flat[15:8];  // 第 1 顆像素的 Trace
    wire [7:0] debug_trace_7 = trace_out_flat[63:56]; // 第 7 顆像素的 Trace

    // =======================================================
    // 2. 實例化 DUT (Device Under Test)
    // =======================================================
    pre_trace #(
        .T_WIDTH(T_WIDTH),
        .BATCH_NUM(BATCH_NUM),
        .N_PARALLEL(N_PARALLEL),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .update_en      (update_en),
        .addr_in        (addr_in),
        .spikes_in      (spikes_in),
        .trace_out_flat (trace_out_flat)
    );

    // =======================================================
    // 3. 時脈產生
    // =======================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =======================================================
    // 4. 測試流程
    // =======================================================
    initial begin
        $display("=== Unit Test: pre_trace Module ===");
        
        // --- Step 1: 初始化 ---
        rst_n = 1; update_en = 0; addr_in = 0; spikes_in = 0;
        #(CLK_PERIOD*2); rst_n = 0; // 重置
        #(CLK_PERIOD*2); rst_n = 1;
        #(CLK_PERIOD);

        // --- Step 2: 測試「充電 (Charge)」 ---
        // 情境：針對地址 5，讓第 0 顆像素發火 (Spike = 1)
        $display("\n[Test 1] Charge: Addr 5, Pixel 0 fires");
        
        addr_in   = 7'd5;
        spikes_in = 8'b0000_0001; // 第 0 顆 bit 是 1
        update_en = 1;
        
        @(posedge clk); // 等待寫入
        #1; // 稍微延遲以便觀察輸出
        
        // 檢查結果
        if (debug_trace_0 === 8'd255) 
            $display("  -> PASS: Trace became 255 instantly.");
        else 
            $display("  -> FAIL: Expected 255, got %d", debug_trace_0);

        // --- Step 3: 測試「其他地址互不影響」 ---
        // 情境：切換到地址 6，應該讀到 0 (因為地址 5 的修改不應影響地址 6)
        $display("\n[Test 2] Independence: Check Addr 6 (Should be 0)");
        
        update_en = 0; // 先關閉寫入，純觀察 (雖然 pre_trace 主要是寫入時才有輸出，但我們可以透過 update_en=1, spikes=0 來讀取並寫回)
        
        addr_in   = 7'd6;
        spikes_in = 8'b0000_0000;
        update_en = 1; // 啟動讀取運算流程
        
        @(posedge clk); 
        #1;
        
        if (debug_trace_0 === 8'd0) 
            $display("  -> PASS: Addr 6 is clean (0).");
        else 
            $display("  -> FAIL: Addr 6 is dirty! Got %d", debug_trace_0);

        // --- Step 4: 測試「衰減 (Decay)」 ---
        // 情境：回到地址 5，但這次不發火 (Spike = 0)。
        // 預期：原本的 255 應該要衰減成 192。
        $display("\n[Test 3] Decay: Back to Addr 5, No Spike");
        
        addr_in   = 7'd5;
        spikes_in = 8'b0000_0000; 
        update_en = 1;
        
        @(posedge clk); 
        #1;
        
        // [修正] 不要看 output wire，直接看內部記憶體
        // 語法：u_dut.trace_mem[地址]
        // 注意：因為 trace_mem 是寬度 64 bits 的，我們只看最低 8 bits (第 0 顆像素)
        if (u_dut.trace_mem[5][7:0] === 8'd192) 
            $display("  -> PASS: Trace decayed correctly (255 -> 192).");
        else 
            $display("  -> FAIL: Decay error. Mem holds %d (Wire sees %d)", u_dut.trace_mem[5][7:0], debug_trace_0);

        // --- Step 5: 測試「連續衰減」 ---
        // 情境：再對地址 5 操作一次 Spike = 0
        // 預期：192 -> 144
        $display("\n[Test 4] Second Decay: Addr 5, No Spike again");
        
        @(posedge clk); 
        #1;
        
        // [修正] 同樣檢查內部記憶體
        if (u_dut.trace_mem[5][7:0] === 8'd144) 
            $display("  -> PASS: Trace decayed again (192 -> 144).");
        else 
            $display("  -> FAIL: Second decay error. Mem holds %d (Wire sees %d)", u_dut.trace_mem[5][7:0], debug_trace_0);
            
        // --- Step 6: 測試多像素平行處理 ---
        // 情境：地址 10，Pixel 0 和 Pixel 7 同時發火
        $display("\n[Test 5] Parallel: Addr 10, Pixel 0 & 7 fire");
        addr_in = 7'd10;
        spikes_in = 8'b1000_0001;
        update_en = 1;
        
        @(posedge clk);
        #1;
        
        if (debug_trace_0 == 255 && debug_trace_7 == 255 && debug_trace_1 == 0)
            $display("  -> PASS: Pixel 0 & 7 set to 255, Pixel 1 stays 0.");
        else
            $display("  -> FAIL: Parallel processing error. P0=%d, P7=%d", debug_trace_0, debug_trace_7);

        $display("\n=== Test Finished ===");
        $finish;
    end

endmodule
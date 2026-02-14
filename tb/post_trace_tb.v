`timescale 1ns/1ps

module post_trace_tb;

    // ============================================================
    // 1. 參數與訊號宣告
    // ============================================================
    parameter NUM_POST    = 1;
    parameter T_WIDTH     = 8;
    parameter DECAY_SHIFT = 2; 

    reg                     clk;
    reg                     rst_n;
    reg                     update_en;
    reg  [NUM_POST-1:0]     fire_in;
    wire [NUM_POST*T_WIDTH-1:0] trace_out_flat;

    // 監測內部寄存器用 (除錯方便)
    wire [T_WIDTH-1:0] debug_trace_val = trace_out_flat[T_WIDTH-1:0];

    // ============================================================
    // 2. 實例化 DUT (Device Under Test)
    // ============================================================
    post_trace #(
        .NUM_POST(NUM_POST),
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .update_en(update_en),
        .fire_in(fire_in),
        .trace_out_flat(trace_out_flat)
    );

    // ============================================================
    // 3. 時脈產生 (100MHz = 10ns period)
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // 4. 測試流程
    // ============================================================
    initial begin
        // --- 波形傾印設定 ---
        // 檔名必須與 run_rtl.sh 預期的 post_trace_tb.fsdb 一致
        $fsdbDumpfile("post_trace_tb.fsdb");
        $fsdbDumpvars(0, post_trace_tb, "+all");

        // --- 初始化 ---
        clk = 0;
        rst_n = 0;
        update_en = 0;
        fire_in = 0;

        #25 rst_n = 1; // 避開時脈正緣重置
        #20;

        // --------------------------------------------------------
        // Test 1: 神經元發火並觸發更新 (LTP)
        // --------------------------------------------------------
        $display("\n[Test 1] Fire in & Update Enable");
        @(negedge clk);     // 在負緣給予訊號，確保正緣採樣穩定 
        fire_in[0] = 1'b1;
        update_en  = 1'b1;

        @(posedge clk);     // 第一個正緣：寫入 255
        #1;                 // 稍微延遲以觀察輸出
        if (debug_trace_val == 255) 
            $display("Time %0t | Success: Trace jumped to 255", $time);
        else 
            $display("Time %0t | Fail: Trace is %d (Expected 255)", $time, debug_trace_val);

        // --------------------------------------------------------
        // Test 2: 鎖存功能測試 (Hold for 98 cycles)
        // --------------------------------------------------------
        $display("\n[Test 2] Scanning Phase: Hold value for 98 cycles");
        @(negedge clk);
        fire_in[0] = 1'b0;
        update_en  = 1'b0;  // 關閉更新，進入鎖存狀態 

        repeat(98) begin
            @(posedge clk);
            #1;
            if (debug_trace_val != 255) begin
                $display("Time %0t | Fail: Trace decayed to %d during hold!", $time, debug_trace_val);
                $finish;
            end
        end
        $display("Time %0t | Success: Value held steady for 98 cycles", $time);

        // --------------------------------------------------------
        // Test 3: 單次衰減測試 (LTD)
        // --------------------------------------------------------
        $display("\n[Test 3] Update Phase: Single decay step (No fire)");
        // 預期：255 - (255 >> 2) = 255 - 63 = 192 
        @(negedge clk);
        update_en = 1'b1;   // 觸發單次更新

        @(posedge clk);
        #1;
        $display("Time %0t | Decay result: %d (Expected ~192)", $time, debug_trace_val);
        
        @(negedge clk);
        update_en = 1'b0;   // 再次鎖存

        // --------------------------------------------------------
        // Test 4: 持續衰減直到歸零 (死鎖防治測試)
        // --------------------------------------------------------
        $display("\n[Test 4] Continuous Decay Test");
        repeat(20) begin
            @(negedge clk);
            update_en = 1'b1;
            @(posedge clk);
            #1;
            update_en = 1'b0;
            $display("Time %0t | Trace Val: %d", $time, debug_trace_val);
        end

        $display("\nAll Tests Finished!");
        #100;
        $finish;
    end

endmodule

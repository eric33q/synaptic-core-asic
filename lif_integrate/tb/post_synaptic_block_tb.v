`timescale 1ns/1ps

module post_synaptic_block_tb;

    // =======================================================
    // 1. 參數定義
    // =======================================================
    parameter D_WIDTH     = 8;
    parameter I_WIDTH     = 18;
    parameter V_WIDTH     = 19;
    parameter THRESHOLD   = 800;
    parameter LEAK_SHIFT  = 3; // V_mem decay
    parameter REF_PERIOD  = 3;
    
    parameter T_WIDTH     = 8;
    parameter DECAY_SHIFT = 2; // Trace decay: x * 0.75

    // =======================================================
    // 2. 信號宣告
    // =======================================================
    reg clk;
    reg rst_n;
    reg input_valid;
    reg start_of_frame;
    reg [63:0] weight_mem;

    wire post_spike;
    wire [T_WIDTH-1:0] post_trace;
    wire [V_WIDTH-1:0] V_mem_out;

    // =======================================================
    // 3. 實例化 DUT (整合後的模組)
    // =======================================================
    post_synaptic_block #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD),
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .input_valid(input_valid),
        .start_of_frame(start_of_frame),
        .weight_mem(weight_mem),
        .post_spike(post_spike),
        .post_trace(post_trace),
        .V_mem_out(V_mem_out)
    );
    initial begin
        $fsdbDumpfile("post_synaptic_block.fsdb");
        $fsdbDumpvars(0, post_synaptic_block_tb, "+all");
    end
    // =======================================================
    // 4. 時鐘生成
    // =======================================================
    always #5 clk = ~clk;

    // =======================================================
    // 5. 測試任務：送入完整的一張圖 (Frame)
    // =======================================================
    task feed_frame(input [7:0] val, input debug_msg);
        integer i;
        begin
            if(debug_msg) $display("--- Start Frame (98 Batches) with Weight = %d ---", val);
            
            // Start Pulse
            @(posedge clk); #1;
            start_of_frame = 1;
            @(posedge clk); #1;
            start_of_frame = 0;

            // Data Streaming
            input_valid = 1;
            weight_mem = {8{val}}; 
            
            for (i=0; i<98; i=i+1) begin
                @(posedge clk); 
            end

            // End of Stream
            #1;
            input_valid = 0;
            weight_mem = 0;
            
            // 等待更新完成 (LIF Update + Trace Update)
            // 這是最關鍵的時刻，我們等 2 個 cycle 讓訊號穩定
            repeat(2) @(posedge clk);
            #1;
            
            if(debug_msg) begin
                $display("--- Frame Done. V_mem=%d, Spike=%b, Trace=%d ---", 
                         V_mem_out, post_spike, post_trace);
            end
        end
    endtask

    // 監聽 Spike (因為它只出現 1 個 cycle)
    always @(posedge clk) begin
        if (post_spike) begin
            $display("[MONITOR] >>> SPIKE FIRED at time %t! (Trace should charge to 255)", $time);
        end
    end

    // =======================================================
    // 6. 主要測試流程
    // =======================================================
    initial begin
        clk = 0;
        rst_n = 0;
        input_valid = 0;
        start_of_frame = 0;
        weight_mem = 0;

        #20 rst_n = 1;
        #20;

        $display("=== TEST START: Post-Synaptic Block Integration ===");

        // ----------------------------------------------------------------
        // Case 1: 初始狀態 (Initial State)
        // ----------------------------------------------------------------
        // 輸入 0，確認 Trace 維持 0
        feed_frame(8'd0, 1); 
        if (post_trace == 0) $display("[PASS] Initial Trace is 0.");
        else $display("[FAIL] Initial Trace is %d", post_trace);


        // ----------------------------------------------------------------
        // Case 2: 強制發火 (Fire & Charge)
        // ----------------------------------------------------------------
        // 輸入大電流 (10)，保證超過閾值 (800)
        // 預期：Spike = 1, Trace 瞬間變 255
        $display("\n[TEST] Triggering Spike...");
        feed_frame(8'd10, 1);

        // 注意：feed_frame 結束時是在發火後的幾個 cycle，Trace 應該已經充飽並保持
        // (因為下一次 update 還沒來，Trace 應該維持 255)
        if (post_trace == 255) 
            $display("[PASS] Trace Charged to 255 upon firing.");
        else 
            $display("[FAIL] Trace failed to charge. Got %d", post_trace);


        // ----------------------------------------------------------------
        // Case 3: 衰減測試 (Decay without Fire) - Frame 1
        // ----------------------------------------------------------------
        // 輸入 0，LIF 不會發火。
        // 預期：LIF 漏電，Trace 也要衰減。
        // Trace 公式：255 - (255 >> 2) = 255 - 63 = 192
        $display("\n[TEST] Feeding Zeros (Expect Decay)...");
        feed_frame(8'd0, 1);

        if (post_trace == 192)
            $display("[PASS] Trace Decayed correctly (255 -> 192).");
        else
            $display("[FAIL] Trace Decay Error. Expected 192, got %d", post_trace);


        // ----------------------------------------------------------------
        // Case 4: 衰減測試 (Decay without Fire) - Frame 2
        // ----------------------------------------------------------------
        // 繼續輸入 0。
        // Trace 公式：192 - (192 >> 2) = 192 - 48 = 144
        feed_frame(8'd0, 1);

        if (post_trace == 144)
            $display("[PASS] Trace Decayed again (192 -> 144).");
        else
            $display("[FAIL] Trace Decay Error. Expected 144, got %d", post_trace);

        
        // ----------------------------------------------------------------
        // Case 5: 再次發火 (Re-Fire)
        // ----------------------------------------------------------------
        // 再次輸入大電流。
        // 預期：Trace 從 144 直接跳回 255。
        $display("\n[TEST] Re-firing...");
        feed_frame(8'd10, 1);
        
        if (post_trace == 255)
            $display("[PASS] Trace Re-charged to 255.");
        else
            $display("[FAIL] Trace Re-charge Error. Got %d", post_trace);

        $display("\n=== TEST END ===");
        $finish;
    end

endmodule
`timescale 1ns/1ps

module post_trace_tb;

    // =======================================================
    // 1. 參數定義
    // =======================================================
    parameter NUM_POST    = 1;
    parameter T_WIDTH     = 8;
    parameter DECAY_SHIFT = 2; // 衰減公式: x - (x >> 2) => x * 0.75

    // =======================================================
    // 2. 信號宣告
    // =======================================================
    reg clk;
    reg rst_n;
    reg update_en;          // 控制是否更新 Trace
    reg [NUM_POST-1:0] fire_in;

    wire [NUM_POST*T_WIDTH-1:0] trace_out_flat;

    // 方便觀察用的 monitor 變數 (假設 NUM_POST=1)
    wire [T_WIDTH-1:0] trace_val = trace_out_flat[T_WIDTH-1:0];

    // =======================================================
    // 3. 實例化 DUT (Device Under Test)
    // =======================================================
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
        initial
    begin
        $fsdbDumpfile("post_trace.fsdb");
        $fsdbDumpvars(0, post_trace_tb, "+all");
    end
    // =======================================================
    // 4. 時鐘生成 (10ns)
    // =======================================================
    always #5 clk = ~clk;

    // =======================================================
    // 5. 測試任務 (修正版)
    // =======================================================
    
    // 觸發一次發火
    task trigger_fire;
        begin
            // 1. 等待時鐘邊緣，並過一點時間 (避開競爭)
            @(posedge clk);
            #1; 
            
            // 2. 設定輸入 (Setup)
            fire_in = 1;
            update_en = 1;
            
            // 3. 等待下一個時鐘邊緣 (Sampling Edge)
            // 這時候 DUT 會在 edge 抓到 fire_in=1, update_en=1
            @(posedge clk); 
            
            // 4. 確保 DUT 抓完後才關閉 (Hold Time)
            #1; 
            fire_in = 0;
            update_en = 0;
            
            // 5. 顯示結果
            #1; 
            $display("[TIME %t] Fire! Trace should be 255. Actual: %d", $time, trace_val);
        end
    endtask

    // 執行 N 次衰減更新 (修正版：連續模式)
    task run_decay(input integer steps);
        integer i;
        begin
            $display("--- Start Decay for %d steps ---", steps);
            
            // 1. 先設定好輸入 (Setup)
            // 確保避開時鐘邊緣
            @(posedge clk);
            #1;
            fire_in = 0;
            update_en = 1; // 讓它保持開啟 (Continuous Mode)

            // 2. 開始計數 N 個時鐘週期
            for(i=0; i<steps; i=i+1) begin
                // 等待硬體更新 (Update Edge)
                @(posedge clk); 
                
                // 稍微等一下讓數值穩定 (Hold Time)
                #1; 
                
                // 觀察
                $display("[Step %0d] Trace: %d", i+1, trace_val);
            end
            
            // 3. 結束後關閉
            update_en = 0;
        end
    endtask

    // =======================================================
    // 6. 主要測試流程
    // =======================================================
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        update_en = 0;
        fire_in = 0;

        // Reset
        #20 rst_n = 1;
        #20;

        $display("=== TEST START ===");

        // ---------------------------------------------------
        // Case 1: 充能測試 (Charge)
        // ---------------------------------------------------
        trigger_fire; // [修正] 移除括號 ()
        
        if (trace_val == 255) 
            $display("[PASS] Charge successful.");
        else 
            $display("[FAIL] Charge failed. Expected 255, got %d", trace_val);

        // ---------------------------------------------------
        // Case 2: 保持測試 (Hold / No Update)
        // ---------------------------------------------------
        repeat(5) @(posedge clk);
        if (trace_val == 255) 
            $display("[PASS] Hold successful. Value remains 255 when update_en=0.");
        else 
            $display("[FAIL] Hold failed. Trace changed to %d", trace_val);

        // ---------------------------------------------------
        // Case 3: 指數衰減測試 (Exponential Decay)
        // ---------------------------------------------------
        run_decay(3); // 有參數的 task 必須保留括號，這是對的
        
        if (trace_val == 108)
            $display("[PASS] Exponential decay correct (255->192->144->108).");
        else
            $display("[FAIL] Exponential decay error. Got %d", trace_val);

        // ---------------------------------------------------
        // Case 4: 長尾截斷測試 (Tail Decay)
        // ---------------------------------------------------
        $display("--- Running long decay until value is small ---");
        run_decay(15); 
        
        // 再跑 10 步確保歸零
        run_decay(10);
        
        if (trace_val == 0)
            $display("[PASS] Tail decay correct. Trace reached 0.");
        else
            $display("[FAIL] Tail decay error. Trace stuck at %d", trace_val);

        $display("=== TEST END ===");
        $finish;
    end

endmodule
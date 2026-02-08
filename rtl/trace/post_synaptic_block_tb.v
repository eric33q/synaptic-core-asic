module post_synaptic_block_tb;

    // --- 參數設定 ---
    parameter V_WIDTH = 19;
    parameter T_WIDTH = 8;
    parameter CLK_PERIOD = 10; // 10ns -> 100MHz

    // --- 訊號宣告 ---
    reg          clk;
    reg          rst_n;
    reg          accum_en;
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
        weight_mem_in = 64'd0;
        
        $display("=== Simulation Start ===");
        
        // 2. 系統重置
        #(CLK_PERIOD * 2);
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // -------------------------------------------------------
        // 測試情境 1: 給予大權重，強迫神經元發火 (Spike)
        // -------------------------------------------------------
        $display("Test 1: Force Firing...");
        
        // 設定權重為最大值 (確保積分後超過 Threshold)
        // 假設 Threshold=800，這裡給 8個 255 (總和 2040)，一定會爆
        weight_mem_in = {8{8'hFF}}; 
        
        // 開啟 accum_en 模擬 98 個 cycle 的積分過程
        accum_en = 1;
        
        // 讓它跑直到發火
        wait(spike_out == 1);
        $display("  -> Spike Detected at time %t!", $time);
        
        // [修正] 多等一個 Clock，讓 Post-Trace 模組有時間更新暫存器
        @(posedge clk); 
        #1; // 稍微再等一點點時間，避開訊號邊緣
        
        if (post_trace_8x[7:0] == 8'hFF) 
            $display("  -> Trace Check PASS: Trace reset to 255.");
        else
            $display("  -> Trace Check FAIL: Trace is %d (Expected 255).", post_trace_8x[7:0]);

        // -------------------------------------------------------
        // 測試情境 2: 觀察 Trace 衰減 (Decay)
        // -------------------------------------------------------
        $display("Test 2: Checking Trace Decay...");
        
        // 關閉輸入 (權重歸零，Enable 關閉)
        weight_mem_in = 64'd0;
        accum_en = 0; // 停止積分，神經元進入 Leak 狀態
        
        // 觀察接下來幾個 Cycle 的變化
        repeat(5) begin
            @(posedge clk);
            $display("  Time %t: Spike=%b, Trace=%d", $time, spike_out, post_trace_8x[7:0]);
        end

        // 簡單驗證：衰減後應該小於 255
        if (post_trace_8x[7:0] < 8'hFF)
            $display("  -> Decay Check PASS: Trace is decaying.");
        else
            $display("  -> Decay Check FAIL: Trace is not changing.");

        // -------------------------------------------------------
        // 測試結束
        // -------------------------------------------------------
        #(CLK_PERIOD * 10);
        $display("=== Simulation Done ===");
        $finish;
    end

    // (選用) 產生波形檔，方便用 Verdi/GTKWave 查看
    initial begin
        $fsdbDumpfile("post_synaptic.fsdb");
        $fsdbDumpvars(0, post_synaptic_block_tb);
    end

endmodule
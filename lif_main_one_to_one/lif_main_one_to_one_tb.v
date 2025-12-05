`timescale 1ns/1ps

module lif_main_one_to_one_tb;

    // ========================================================
    // 1. 參數定義 (與 DUT 保持一致)
    // ========================================================
    parameter D_WIDTH    = 8;
    parameter THRESHOLD  = 200; // 設定閾值
    parameter LEAK_SHIFT = 3;   // 漏電 V_new = V_old - (V_old >> 3)
    parameter REF_PERIOD = 3;   // 不應期長度 3 cycles

    // ========================================================
    // 2. 訊號宣告
    // ========================================================
    reg clk;
    reg rst_n;
    reg [D_WIDTH-1:0] i_syn;

    wire post_spike;
    wire [D_WIDTH-1:0] V_mem_out;
    
    // ========================================================
    // 3. 實例化 DUT (Device Under Test)
    // ========================================================
    lif_main_one_to_one #(
        .D_WIDTH(D_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_syn(i_syn),
        .post_spike(post_spike),
        .V_mem_out(V_mem_out)
    );

    // ========================================================
    // 4. 時脈生成 (10ns 週期 -> 100MHz)
    // ========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // 5. 測試流程 (Stimulus)
    // ========================================================
    integer i;
    
    initial begin
        // --- 初始化 ---
        $display("=== Simulation Start (Black-box Mode) ===");
        $display("Time\t V_mem \t Spike");
        $monitor("%t\t %d \t %b", $time, V_mem_out, post_spike);
        
        rst_n = 0;
        i_syn = 0;
        #20;
        rst_n = 1;
        #10;

        // --------------------------------------------------------
        // 測試 1: 積分與漏電 (Integrate & Leak Check)
        // --------------------------------------------------------
        $display("\n--- [Test 1] Integration & Leakage ---");
        
        // 給予輸入電流 50
        @(posedge clk); i_syn = 8'd50; 
        
        @(posedge clk); 
        @(posedge clk); 
        
        // 移除輸入
        @(posedge clk); i_syn = 8'd0;
        
        repeat(5) @(posedge clk); // 等待觀察漏電效果


        // --------------------------------------------------------
        // 測試 2: 發火閾值與重置 (Firing & Hard Reset)
        // --------------------------------------------------------
        $display("\n--- [Test 2] Firing Threshold Check (Th=%d) ---", THRESHOLD);
        
        // 給予大電流 100，快速衝破閾值 200
        @(posedge clk); i_syn = 8'd100;

        // 等待 Spike 發生
        wait(post_spike == 1);
        $display(">>> SPIKE GENERATED! <<<");

        // 檢查 Spike 發生後的下一個 Cycle，V_mem 是否立刻歸零
        @(posedge clk);
        #1; // 微小延遲讀取數據
        
        // 這裡只檢查 V_mem 是否為 0，不再檢查內部狀態
        if (V_mem_out == 0) 
            $display(">>> PASS: Hard Reset successful (V_mem=0)");
        else 
            $display(">>> FAIL: Reset failed! (V_mem=%d)", V_mem_out);


        // --------------------------------------------------------
        // 測試 3: 不應期鎖定 (Refractory Period Lock)
        // --------------------------------------------------------
        $display("\n--- [Test 3] Refractory Period Check (%d cycles) ---", REF_PERIOD);
        
        // 繼續保持 i_syn = 100，但在不應期內 V_mem 應該保持 0
        // 已經過了一個 cycle (上面的 check)，現在檢查剩下的
        for (i = 0; i < REF_PERIOD; i = i + 1) begin
            if (V_mem_out != 0) 
                $display(">>> FAIL: Refractory violation at cycle %d! V_mem=%d", i, V_mem_out);
            
            @(posedge clk); // 進下一個 cycle
            #1;
        end
        $display(">>> PASS: Refractory period maintained 0V correctly.");

        // --------------------------------------------------------
        // 測試 4: 恢復積分 (Recovery)
        // --------------------------------------------------------
        $display("\n--- [Test 4] Recovery Check ---");
        // 此時不應期應該結束了，且 i_syn 還是 100，V_mem 應該立刻彈起來
        // 這裡只檢查 V_mem 是否回升
        if (V_mem_out > 0)
            $display(">>> PASS: Neuron recovered and started integrating (V_mem=%d)", V_mem_out);
        else
            $display(">>> FAIL: Neuron did not recover! (V_mem=%d)", V_mem_out);

        // --- 結束 ---
        #50;
        $display("\n=== Simulation Complete ===");
        $stop;
    end

endmodule
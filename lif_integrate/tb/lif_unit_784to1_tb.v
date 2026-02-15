`timescale 1ns/1ps

module lif_unit_784to1_tb;

    // =======================================================
    // 1. 參數定義
    // =======================================================
    parameter D_WIDTH    = 8;
    parameter I_WIDTH    = 18;
    parameter V_WIDTH    = 19;
    parameter THRESHOLD  = 800; 
    parameter LEAK_SHIFT = 3;   
    parameter REF_PERIOD = 3;   

    // =======================================================
    // 2. 信號宣告
    // =======================================================
    reg clk;
    reg rst_n;
    reg input_valid;
    reg start_of_frame;
    reg [63:0] weight_mem; 

    wire post_spike;
    wire sim_step_done; // [新增] 同步信號
    wire [V_WIDTH-1:0] V_mem_out;

    // =======================================================
    // 3. 實例化 DUT (Device Under Test)
    // =======================================================
    lif_unit_784to1 #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .input_valid(input_valid),
        .start_of_frame(start_of_frame),
        .weight_mem(weight_mem),
        .post_spike(post_spike),
        .sim_step_done(sim_step_done), // [連接] 新增的端口
        .V_mem_out(V_mem_out)
    );
    initial begin
        $fsdbDumpfile("lif_unit_784to1.fsdb");
        $fsdbDumpvars(0, lif_unit_784to1_tb, "+all");
    end
    // =======================================================
    // 4. 時鐘生成 (10ns 週期 -> 100MHz)
    // =======================================================
    always #5 clk = ~clk;

    // =======================================================
    // 5. 監聽器 (Monitor) - 捕捉瞬間脈衝
    // =======================================================
    always @(posedge clk) begin
        if (post_spike) begin
            $display("[MONITOR] >>> Spike Detected at time %t! V_mem was %d", $time, V_mem_out);
        end
    end

    // =======================================================
    // 6. 測試任務 (Helper Task)
    // =======================================================
    task feed_one_image(input [7:0] val);
        integer i;
        begin
            $display("--- Start Processing Image (98 Batches) with Weight = %d ---", val);
            
            // 1. Start Frame 信號
            @(posedge clk); #1;
            start_of_frame = 1;
            @(posedge clk); #1;
            start_of_frame = 0;

            // 2. 連續發送 98 筆資料
            input_valid = 1;
            weight_mem = {8{val}}; 
            
            for (i=0; i<98; i=i+1) begin
                @(posedge clk); 
            end

            // 3. [新增] 檢查同步信號 sim_step_done
            // 在第 98 個 Cycle 結束後，sim_step_done 應該要拉高
            #1; // 等待數據穩定
            if (sim_step_done === 1'b1)
                $display("[CHECK] Sync Signal: sim_step_done ASSERTED correctly.");
            else
                $display("[FAIL] Sync Signal: sim_step_done FAILED to assert.");

            // 4. 結束輸入
            input_valid = 0;
            weight_mem = 0;
            
            // 5. 等待幾個週期讓神經元完成 Update
            repeat(5) @(posedge clk);
            
            $display("--- Image Processed. Current V_mem = %d ---", V_mem_out);
        end
    endtask

    // =======================================================
    // 7. 主要測試流程
    // =======================================================
    initial begin
        // 初始化信號
        clk = 0;
        rst_n = 0;
        input_valid = 0;
        start_of_frame = 0;
        weight_mem = 0;

        // 系統重置
        #20 rst_n = 1;
        #20;

        $display("=== TEST START ===");

        // ---------------------------------------------------
        // Case 1: 累積測試 (Integration)
        // ---------------------------------------------------
        feed_one_image(8'd1); // 總電流 784
        
        if (V_mem_out == 784) 
            $display("[PASS] Case 1: Integration correct. V_mem is 784.");
        else 
            $display("[FAIL] Case 1: Expected 784, got %d", V_mem_out);

        // ---------------------------------------------------
        // Case 2: 漏電測試 (Leakage)
        // ---------------------------------------------------
        feed_one_image(8'd0); // 總電流 0 -> 只有漏電
        
        // 784 - (784>>3) = 784 - 98 = 686
        if (V_mem_out == 686) 
            $display("[PASS] Case 2: Leakage correct. V_mem decayed to 686.");
        else 
            $display("[FAIL] Case 2: Expected 686, got %d", V_mem_out);

        // ---------------------------------------------------
        // Case 3: 發火測試 (Firing)
        // ---------------------------------------------------
        // 當前 686, 輸入 784 -> 超過 800 -> 發火並歸零
        feed_one_image(8'd1); 
        
        if (V_mem_out == 0) 
            $display("[PASS] Case 3: Reset correct (V_mem is 0). Check MONITOR for Spike.");
        else 
            $display("[FAIL] Case 3: Expected V_mem 0, got %d", V_mem_out);
        
        // ---------------------------------------------------
        // Case 4: 不應期測試 (Refractory)
        // ---------------------------------------------------
        // 輸入大電流，確認神經元能否再次運作
        feed_one_image(8'd10);
        
        if (V_mem_out == 0) // 再次發火並重置
            $display("[PASS] Case 4: Recovered and Fired again.");
        else
            $display("[FAIL] Case 4: Failed to fire again.");

        $display("=== TEST END ===");
        $finish;
    end

endmodule
`timescale 1ns / 1ps

module lif_unit_64to1_tb;

    // ============================================================
    // 1. 參數定義 (Parameters)
    // ============================================================
    parameter D_WIDTH    = 8;
    parameter I_WIDTH    = 15;
    parameter V_WIDTH    = 15;
    parameter THRESHOLD  = 200;
    parameter LEAK_SHIFT = 3;   
    parameter REF_PERIOD = 3;   
    parameter CLK_PERIOD = 10;  

    // ============================================================
    // 2. 訊號宣告 (使用 reg/wire 取代 logic, int 取代為 integer)
    // ============================================================
    reg clk;
    reg rst_n;
    
    // 測試輔助用 Array (TB 內部使用)
    reg [D_WIDTH-1:0] weight_in [7:0]; 
    
    // 接給 DUT 的扁平向量
    reg [(D_WIDTH*8)-1:0] weight_flat;

    // DUT 輸出 (必須用 wire)
    wire post_spike;
    wire [V_WIDTH-1:0] V_mem_out;

    // 迴圈變數 (Verilog-2001 必須宣告在 initial/always 外部或開頭)
    integer i; 

    // ============================================================
    // 3. 待測物實例化 (DUT Instantiation)
    // ============================================================
    lif_unit_64to1 #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_flat(weight_flat), 
        .post_spike(post_spike),
        .V_mem_out(V_mem_out)
    );

    // ============================================================
    // 4. 時脈生成 (Clock Generation)
    // ============================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $fsdbDumpfile("lif_unit_64to1.fsdb");
        $fsdbDumpvars(0, lif_unit_64to1_tb, "+all");
    end
    // ============================================================
    // 5. 測試流程 (Test Scenario)
    // ============================================================
    initial begin
        // --- 0. 初始化 ---
        $display("=== Simulation Start ===");
        rst_n = 0;
        weight_flat = 0;
        
        // 迴圈初始化
        for(i=0; i<8; i=i+1) begin
            weight_in[i] = 0;
        end
        
        repeat(2) @(posedge clk);
        rst_n = 1;
        $display("[Time %0t] Reset released.", $time);
        
        // 等待穩定
        repeat(16) @(posedge clk);

        // --- 1. 測試積分與漏電 ---
        $display("\n--- Test Case 1: Integration & Leak ---");
        $display("Sending small currents...");
        
        drive_timestep(40); 
        $display("[Time %0t] V_mem = %0d (Expected ~40)", $time, V_mem_out);

        drive_timestep(0);
        $display("[Time %0t] V_mem after leak = %0d (Expected ~35)", $time, V_mem_out);

        drive_timestep(0);
        $display("[Time %0t] V_mem after 2nd leak = %0d (Expected ~31)", $time, V_mem_out);

        // --- 2. 測試發火 ---
        $display("\n--- Test Case 2: Fire Test (Threshold = 200) ---");
        drive_timestep(200); 
        
        if (post_spike) 
            $display("[SUCCESS] Spike detected! V_mem = %0d", V_mem_out);
        else 
            $display("[FAILURE] No Spike? V_mem = %0d", V_mem_out);

        // --- 3. 測試不應期 ---
        $display("\n--- Test Case 3: Refractory Period ---");
        
        $display("Applying input during refractory period...");
        drive_timestep(100); 
        $display("[Refractory 1] V_mem = %0d (Expected 0)", V_mem_out);
        
        drive_timestep(100);
        $display("[Refractory 2] V_mem = %0d (Expected 0)", V_mem_out);

        drive_timestep(100);
        $display("[Refractory 3] V_mem = %0d (Expected 0)", V_mem_out);

        drive_timestep(50);
        $display("[Refractory Done] V_mem = %0d (Expected ~50)", V_mem_out);

        // --- 結束模擬 ---
        $display("\n=== Simulation Finished ===");
        #50;
        $stop;
    end

    // ============================================================
    // Task: 模擬單一時間步
    // (修正：使用 Verilog-2001 語法，參數宣告在括號外)
    // ============================================================
    task drive_timestep;
        input [31:0] total_input_val; // int 改為固定位寬
        
        integer group_idx;
        integer val_per_group;
        integer remainder;
        integer k; // 迴圈變數
        integer p; // 打包用的迴圈變數
        
        begin
            val_per_group = total_input_val / 8;
            remainder = total_input_val % 8;

            // 執行 8 個 Clock Cycle
            // (修正：i++ 改為 group_idx = group_idx + 1)
            for (group_idx = 0; group_idx < 8; group_idx = group_idx + 1) begin
                
                // 設定 weight_in
                if (group_idx == 7)
                    weight_in[0] = val_per_group + remainder;
                else
                    weight_in[0] = val_per_group;

                for (k=1; k<8; k=k+1) begin
                    weight_in[k] = 0;
                end

                // [修正] 手動打包 (Manual Packing)
                // 取代 {>>{}} 語法，解決 Verilog 報錯
                for (p=0; p<8; p=p+1) begin
                    // 使用 Indexed Part Select (+:)
                    weight_flat[p*D_WIDTH +: D_WIDTH] = weight_in[p];
                end

                @(posedge clk);
            end
            
            #1; 
        end
    endtask

endmodule
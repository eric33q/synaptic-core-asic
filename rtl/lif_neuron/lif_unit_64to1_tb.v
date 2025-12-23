`timescale 1ns/1ps
module lif_unit_64to1_tb;

    // ==========================================
    // 1. 參數設定 (需與 DUT 保持一致)
    // ==========================================
    parameter D_WIDTH    = 8;
    parameter I_WIDTH    = 15;
    parameter V_WIDTH    = 15;
    parameter THRESHOLD  = 200;
    parameter LEAK_SHIFT = 3;
    parameter REF_PERIOD = 3;

    // ==========================================
    // 2. 訊號宣告 (修改重點：轉接橋樑)
    // ==========================================
    reg  clk;
    reg  rst_n;
    
    // 宣告一個扁平的暫存器，方便 TB 賦值 (64 bits total)
    reg  [D_WIDTH*8-1:0] weight_flat;

    // 宣告符合 DUT 接口要求的 Unpacked Wire
    wire [D_WIDTH-1:0]   weight_unpacked [7:0];

    wire post_spike;
    wire [V_WIDTH-1:0] V_mem_out;

    // ==========================================
    // 3. 轉接邏輯 (Packing -> Unpacking Bridge)
    // ==========================================
    // 這段代碼負責將扁平的 weight_flat "切片" 分配給 weight_unpacked
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin : pack_to_unpack
            // weight_flat 的每 8 bits 對應到 weight_unpacked 的一個元素
            assign weight_unpacked[g] = weight_flat[(g*D_WIDTH) +: D_WIDTH];
        end
    endgenerate

    // ==========================================
    // 4. 實例化 DUT (Device Under Test)
    // ==========================================
    lif_unit_64to1 #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_mem(weight_flat), // 連接轉接後的訊號
        .post_spike(post_spike),
        .V_mem_out(V_mem_out)
    );

// 4. [訊號映射] 把扁平的值「解包」給觀測用的陣列看
    genvar gi; 
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : tb_unpack
            // 裡面的 i 也要全部改成 gi
            assign weight_unpacked[gi] = weight_flat[(gi*D_WIDTH) +: D_WIDTH];
        end
    endgenerate
    
    // ==========================================
    // 5. 時脈產生 (100MHz)
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ==========================================
    // 6. 測試任務 (Helper Tasks)
    // ==========================================
    integer i;

    // 任務：發送 64 個輸入 (分 8 個 Cycle)
    // val: 每個權重的數值 (這裡簡化為所有通道數值相同)
    task send_64_inputs;
        input [D_WIDTH-1:0] val;
        begin
            // 當計數器不為 0 時，持續在每個 Clock 正緣等待
            // 直到它在 Clock 正緣被檢測到歸零為止
            while (u_dut.weight_grp_cnt != 3'd0) @(posedge clk);
            
            $display("[Time %0t] Sending 64 inputs with value %d...", $time, val);
            
            for (i = 0; i < 8; i = i + 1) begin
                // 直接對扁平暫存器賦值，語法更簡潔
                // {8{val}} 代表將 val 重複 8 次，填滿 64 bits
                weight_flat <= {8{val}}; 
                @(posedge clk);
            end
            
            // 發送完畢後清零
            weight_flat <= {(D_WIDTH*8){1'b0}};
        end
    endtask

    // 任務：等待 N 個週期
    task wait_cycles;
        input integer n;
        begin
            repeat(n) @(posedge clk);
        end
    endtask

    // ==========================================
    // 7. 主要測試流程
    // ==========================================
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        
        // 確保 Reset 期間輸入是乾淨的
        weight_flat = {(D_WIDTH*8){1'b0}};
        
        #20; rst_n = 1; // 釋放重置
        $display("[Time %0t] Reset released.", $time);
        
        // 確保重置後有足夠時間進入穩定狀態
        wait_cycles(5);

        // --- Test 1: 積分測試 (未達閾值) ---
        // 輸入總和 = 64 * 2 = 128 ( < 200 )
        send_64_inputs(8'd2);
        
        wait_cycles(5); // 等待積分更新
        $display("[Time %0t] V_mem after input 2: %d (Expected ~128)", $time, V_mem_out);

        // --- Test 2: 漏電測試 (Leakage) ---
        $display("[Time %0t] Waiting for leakage...", $time);
        wait_cycles(10); // 等待一段時間讓電位衰減
        $display("[Time %0t] V_mem after leakage: %d (Expected < Previous)", $time, V_mem_out);

        // --- Test 3: 發火測試 (Fire) ---
        // 輸入總和 = 64 * 4 = 256 ( > 200 )
        // 注意：此時 V_mem 可能還有 Test 1 剩餘的殘值，更容易發火
        send_64_inputs(8'd4);
        
        wait_cycles(2); // 等待 Spike 產生
        if (post_spike) 
            $display("[Time %0t] PASS: Spike detected! V_mem: %d", $time, V_mem_out);
        else            
            $display("[Time %0t] FAIL: No spike detected.", $time);

        // --- Test 4: 不應期測試 (Refractory Period) ---
        // Spike 後立即發送強輸入，預期應該被忽略
        $display("[Time %0t] Testing Refractory Period (Sending inputs immediately)...", $time);
        send_64_inputs(8'd5); 
        
        wait_cycles(5);
        $display("[Time %0t] V_mem after refractory input: %d (Expected low/0)", $time, V_mem_out);

        #50; $finish;
    end

    // 產生波形檔 (可選)
    initial begin
        $dumpfile("lif_unit_64to1.vcd");
        $dumpvars(0, lif_unit_64to1_tb);
        // 也可以 dump 內部的 unpacked array，但在 waveform viewer 中可能需要展開看
        for (i=0; i<8; i=i+1) begin
             $dumpvars(0, weight_unpacked[i]); 
        end
    end

endmodule

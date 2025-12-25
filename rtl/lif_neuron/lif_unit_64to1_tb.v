`timescale 1ns/1ps
module lif_unit_64to1_tb;

    // ==========================================
    // 1. 參數設定
    // ==========================================
    parameter D_WIDTH    = 8;
    parameter I_WIDTH    = 15;
    parameter V_WIDTH    = 15;
    parameter THRESHOLD  = 200;
    parameter LEAK_SHIFT = 3;
    parameter REF_PERIOD = 3;

    // ==========================================
    // 2. 訊號宣告
    // ==========================================
    reg  clk;
    reg  rst_n;
    
    // 扁平輸入 (64 bits)
    reg  [D_WIDTH*8-1:0] weight_flat;
    
    // 觀測用陣列 (Unpacked Wire)
    wire [D_WIDTH-1:0]   weight_unpacked [7:0];

    wire post_spike;
    wire [V_WIDTH-1:0] V_mem_out;

    integer i;       // 用於 send_inputs 迴圈
    integer k;       // 用於抓 Spike 的視窗迴圈
    reg spike_found; // 用於標記是否抓到 Spike

    // ==========================================
    // 3. 轉接邏輯 (Packing / Unpacking)
    // ==========================================
    
    // DUT -> TB (扁平轉陣列，方便波形觀測)
    genvar gi; 
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : tb_unpack
            assign weight_unpacked[gi] = weight_flat[(gi*D_WIDTH) +: D_WIDTH];
        end
    endgenerate

    // ==========================================
    // 4. 實例化 DUT
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
        .weight_mem(weight_flat),
        .post_spike(post_spike),
        .V_mem_out(V_mem_out)
    );
    
    // ==========================================
    // 5. 時脈產生
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ==========================================
    // 6. 測試任務
    // ==========================================
    task send_64_inputs;
        input [D_WIDTH-1:0] val;
        begin
            // 訊號同步化：等待 DUT 計數器歸零
            while (u_dut.weight_grp_cnt != 3'd0) @(posedge clk);

            $display("[Time %0t] Sending 64 inputs with value %d...", $time, val);
            
            for (i = 0; i < 8; i = i + 1) begin
                weight_flat <= {8{val}};
                @(posedge clk);
            end
            
            weight_flat <= {(D_WIDTH*8){1'b0}};
        end
    endtask

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
        rst_n = 0;
        weight_flat = {(D_WIDTH*8){1'b0}};
        spike_found = 0; 
        
        #20;
        rst_n = 1;
        $display("[Time %0t] Reset released.", $time);
        
        wait_cycles(5);

        // --- Test 1: 積分測試 ---
        send_64_inputs(8'd2);
        wait_cycles(5);
        $display("[Time %0t] V_mem after input 2: %d (Expected ~128)", $time, V_mem_out);

        // --- Test 2: 漏電測試 ---
        $display("[Time %0t] Waiting for leakage...", $time);
        wait_cycles(10);
        $display("[Time %0t] V_mem after leakage: %d (Expected < Previous)", $time, V_mem_out);

        // --- Test 3: 發火測試 (使用視窗檢測) ---
        send_64_inputs(8'd4);
        
        //使用迴圈給予寬容度，確保抓到只有 1 cycle 的 Spike
        spike_found = 0;
        for(k = 0; k < 10; k = k + 1) begin 
            if(post_spike) spike_found = 1;
            @(posedge clk);
        end

        if(spike_found) 
            $display("[Time %0t] PASS: Spike detected! V_mem: %d", $time, V_mem_out);
        else            
            $display("[Time %0t] FAIL: No spike detected.", $time);

        // --- Test 4: 不應期測試 ---
        $display("[Time %0t] Testing Refractory Period...", $time);
        send_64_inputs(8'd5); 
        
        wait_cycles(5);
        $display("[Time %0t] V_mem after refractory input: %d (Expected low/0)", $time, V_mem_out);

        #50; $finish;
    end

    // 產生 FSDB 波形
    initial begin
        $fsdbDumpfile("lif_unit_64to1.fsdb");
        
        // 1. Dump 所有的標準訊號 (Wire, Reg)
        $fsdbDumpvars(0, lif_unit_64to1_tb);
        
        // 2. Dump 所有的陣列與記憶體 (Multi-Dimensional Arrays)
        // 這行指令會自動處理 weight_unpacked 和 sram_mem，不用手動迴圈
        $fsdbDumpMDA(); 
    end


endmodule

`timescale 1ns/1ps

module layer1_system_top_tb;

    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98;

    // 訊號宣告
    reg  clk, rst_n, start;
    reg  accumulate_en;       // 0:Clear, 1:Accumulate
    reg  [63:0] pixel_data_in;
    
    wire [6:0]  req_addr;
    wire [7:0]  L2_spike_data;
    wire        L2_valid;
    wire        L1_busy;
    wire        L1_done;

    reg [63:0] image_rom [0:BATCH_NUM-1];

    // 實例化 DUT
    layer1_system_top #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM)
    ) u_dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start),
        .accumulate_en(accumulate_en),
        .pixel_data_in(pixel_data_in),
        .req_addr(req_addr),
        .L2_spike_data(L2_spike_data),
        .L2_valid(L2_valid),
        .L1_busy(L1_busy),
        .L1_done(L1_done)
    );

    // 時脈
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin

        $fsdbDumpfile("layer1_system_top.fsdb");

        $fsdbDumpvars(0, layer1_system_top_tb, "+all");

    end
    // 記憶體延遲模擬 (Latency = 1)
    always @(posedge clk) begin
        if (!rst_n) pixel_data_in <= 0;
        else pixel_data_in <= image_rom[req_addr];
    end

    // --- 監控器：直接觀察內部 SRAM ---
    // 目標：Batch 25 (有數據的一行), Neuron 3 (Hex值 B9 = 185)
    // Neuron 3 在 SRAM 中的位置：
    // V_mem = [3*12 +: 8] = [43:36]
    // Ref   = [3*12+8 +: 4] = [47:44]
    wire [95:0] sram_monitor_row = u_dut.u_generator.state_sram[25];
    wire [7:0]  mon_v_mem        = sram_monitor_row[31:24];
    wire [3:0]  mon_ref          = sram_monitor_row[35:32];

    // --- 測試流程 ---
    integer step;
    initial begin
        // 1. 載入圖片
        $readmemh("mnist_input.hex", image_rom);
        
        // 2. 初始化
        rst_n = 1; accumulate_en = 0; start = 0;
        #(CLK_PERIOD*2); rst_n = 0; 
        #(CLK_PERIOD*2); rst_n = 1; 
        #(CLK_PERIOD*2);

        $display("=== SNN Simulation Start: 6 Time Steps ===");
        $display("Target Neuron: Batch 29, Index 0 (Input=254, Threshold=200)");

        // 3. 執行 6 個 Time Steps
        for (step = 1; step <= 6; step = step + 1) begin
            
            // 控制模式：第一次清空，之後累積S
            if (step == 1) accumulate_en = 0;
            else           accumulate_en = 1;

            // 發送 Start (開始跑 98 個 Batch)
            @(posedge clk); start = 1; 
            @(posedge clk); start = 0;

            // 等待整張圖跑完
            wait(L1_done == 1);
            
            // 印出該 Step 結束後的狀態
            // 注意：這裡印出的是 Batch 25 被寫入後的值
            $display("Time Step %0d Finished | Neuron Status: V_mem=%3d, Ref_Cnt=%0d", 
                     step, mon_v_mem, mon_ref);
            
            // 休息一下，方便波形區隔
            #(CLK_PERIOD*10);
        end
        $display("=== Simulation Finished ===");
        $finish;
    end

//     always @(posedge clk) begin
//         if (L2_valid && L2_spike_data != 0) begin
//             $display("  [Spike] Time: %t, Batch: %d, Data: %b", $time, req_addr, L2_spike_data);
//         end
//     end
endmodule
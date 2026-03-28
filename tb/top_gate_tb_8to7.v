`timescale 1ns/1ps

// 定義 SDF 檔案路徑
`define SDFFILE "../../syn/netlist/top_syn.sdf"

module top_gate_tb_8to7; // 💡 重新命名模組名稱以符實驗

    // --- 參數與訊號定義 ---
    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98; 

    reg         clk;
    reg         rst_n;
    reg         start_loading;
    reg  [15:0] data_in;
    
    wire        spike_out;
    wire        busy;
    wire        finish;

    // --- 測試數據記憶體 ---
    reg [63:0] pixel_data_mem [0:BATCH_NUM-1];
    integer i, frame, wait_timeout;
    integer file_out;
    reg [8*100:1] filename; // 加長檔名長度以防路徑過長

    // --- 實例化 DUT ---
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start_loading(start_loading),
        .data_in(data_in),
        .spike_out(spike_out),
        .busy(busy),
        .finish(finish)
    );

    // --- GLS 延遲檔載入 ---
    initial begin
`ifdef SDF
        $sdf_annotate(`SDFFILE, uut);
`endif
    end

    // --- 時脈產生 ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =======================================================
    // 主測試流程：從 8 重新學習 7
    // =======================================================
// =======================================================
    // 主測試流程：從 8 重新學習 7
    // =======================================================
    initial begin
        // 0. 系統重置
        $display("\n=== System Reset & Experiment: 8-to-7 Forgetting ===");
        start_loading = 0;
        rst_n = 0;
        data_in = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // -------------------------------------------------------
        // 💡 關鍵修正 1：喚醒 FSM (Dummy Initialization)
        // 必須先走一次標準載入，讓晶片內部的狀態機就緒
        // -------------------------------------------------------
        $display("\n[Action] Phase 1: Dummy Init to wake up FSM...");
        @(negedge clk);
        start_loading <= 1'b1; 
        @(negedge clk);
        start_loading <= 1'b0; 

        // 隨便餵入雜訊資料 (0x2020) 騙過狀態機
        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            data_in <= 16'h2020; @(negedge clk); 
            data_in <= 16'h2020; @(negedge clk);
            data_in <= 16'h2020; @(negedge clk);
            data_in <= 16'h2020; @(negedge clk);
        end
        data_in <= 16'd0; 
        
        // 等待 FSM 處理完並回到 IDLE (準備好接收 Frame)
        #(CLK_PERIOD * 20);
        $display("[Status] FSM is awake and Ready!");

        // -------------------------------------------------------
        // 💡 關鍵修正 2：「大腦移植」(強行植入數字 8)
        // 趁晶片 Ready 時，把 SRAM 裡面的雜訊洗掉，換成成熟的 8
        // -------------------------------------------------------
        $display("\n[Action] Phase 1.5: Injecting Pre-trained Weights of '8'...");
        $readmemh("/home/t112830022/synaptic-core-asic/sim/top_gate_tb_mnist8/final_weights_frame25_mnist8.txt", uut.u_we.u_sram.mem);
        #(CLK_PERIOD * 10); 

        // -------------------------------------------------------
        // Phase 2: 載入數字 7，開始 100 步的重新學習
        // -------------------------------------------------------
        $display("\n[Action] Phase 2: Loading Training Data of '7'...");
        $readmemh("/home/t112830022/synaptic-core-asic/data/mnist_input_7.hex", pixel_data_mem);

        // 3. 開始訓練過程 (1~100 Frames)
        for (frame = 1; frame <= 100; frame = frame + 1) begin
            $display("--- Frame %0d (Learning Digit 7) ---", frame);
            // ... 底下的 Frame 迴圈與 Timeout 判斷維持不變 ...
            
            @(negedge clk);
            start_loading <= 1'b1; 
            @(negedge clk);
            start_loading <= 1'b0; 

            fork
                // 餵資料流程
                begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        data_in <= pixel_data_mem[i][15:0];  @(negedge clk);
                        data_in <= pixel_data_mem[i][31:16]; @(negedge clk);
                        data_in <= pixel_data_mem[i][47:32]; @(negedge clk);
                        data_in <= pixel_data_mem[i][63:48]; @(negedge clk);
                    end
                    data_in <= 16'd0; 
                end
                
                // 等待 finish 流程
                begin
                    wait_timeout = 0;
                    while (finish == 0 && wait_timeout < 2000) begin
                        @(posedge clk);
                        wait_timeout = wait_timeout + 1;
                    end
                end
            join

            if (wait_timeout >= 2000) begin
                $display("[Error] Frame %0d stuck!", frame); $finish;
            end

            // 🌟 匯出過程：存入專用資料夾以利 Python 畫圖
            if (frame % 5 == 0 || frame == 1) begin // 特別存出第 1 個 frame 看 8 溶解的樣子
                $sformat(filename, "weights_frame_%0d.txt", frame); // 💡 注意：這邊改回原檔名，方便 Python 讀取
                file_out = $fopen(filename, "w");
                if (file_out) begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        $fdisplay(file_out, "%h", uut.u_we.u_sram.mem[i][63:0]); 
                    end
                    $fclose(file_out);
                    $display("Snapshot exported: %0s", filename);
                end
            end
            
            #(CLK_PERIOD * 50);
        end
        
        $display("\n=== Experiment Complete: Check transition_8_to_7.png ===");
        $finish;
    end

    // --- 波形檔 ---
    initial begin
        $fsdbDumpfile("8to7_experiment.fsdb");
        $fsdbDumpvars(0, top_gate_tb_8to7);
        $fsdbDumpMDA;
    end

endmodule

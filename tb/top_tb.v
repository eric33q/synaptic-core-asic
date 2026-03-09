`timescale 1ns/1ps

module top_tb;

    // --- 參數與訊號定義 ---
    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98; 

    reg         clk;
    reg         rst_n;
    reg         start_loading;
    reg  [6:0]  addr_in;
    reg  [15:0] data_in;
    
    wire        spike_out;
    wire        busy;
    wire        finish;

    // --- 測試數據記憶體 ---
    reg [63:0] pixel_data_mem [0:BATCH_NUM-1];
    integer i, frame, wait_timeout;

    // --- 實例化 DUT ---
    top #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start_loading(start_loading),
        .addr_in(addr_in),
        .data_in(data_in),
        .spike_out(spike_out),
        .busy(busy),
        .finish(finish)
    );

    // --- 時脈產生 ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =======================================================
    // 監控區 (FSM 追蹤)
    // =======================================================
    always @(uut.current_mode) begin
        case (uut.current_mode)
            3'd0: $display("[FSM] T=%7t | ST_IDLE", $time);
            3'd1: $display("[FSM] T=%7t | ST_LOAD (Weight Init)", $time);
            3'd2: $display("[FSM] T=%7t | ST_INTEGRATE (Phase 1: Calc Spikes)", $time);
            3'd3: $display("[FSM] T=%7t | ST_CHECK (Phase 1: Wait L2 Latch)", $time);
            3'd4: $display("[FSM] T=%7t | ST_UPDATE (Phase 2: On-the-fly STDP)", $time);
            3'd5: $display("[FSM] T=%7t | ST_FINISH", $time);
    default: $display("[FSM] T=%7t | UNKNOWN (%d)", $time, uut.current_mode);
        endcase
    end

    // =======================================================
    // 主測試流程
    // =======================================================
    initial begin
        // 0. 初始化數據：位址關聯編碼 {Addr, 04, Addr, 03, Addr, 02, Addr, 01}
        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            pixel_data_mem[i] = {i[7:0], 8'h04, i[7:0], 8'h03, i[7:0], 8'h02, i[7:0], 8'h01};
        end

        $display("\n=== System Reset ===");
        start_loading = 0;
        rst_n = 0;
        addr_in = 0;
        data_in = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // -------------------------------------------------------
        // Phase 1: ST_LOAD (載入特徵權重)
        // -------------------------------------------------------
        $display("\n=== Phase 1: ST_LOAD (Weight Initialization) ===");
        
        // 提早發送 Start 脈衝，讓 FSM 有時間切換到 ST_LOAD
        @(posedge clk);
        start_loading <= 1'b1;
        
        @(posedge clk);
        start_loading <= 1'b0; // 關閉 Start，開始無縫餵入資料！

        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            // 餵入 4 拍 16-bit 片段，連續不斷！
            data_in <= pixel_data_mem[i][15:0];  @(posedge clk); 
            data_in <= pixel_data_mem[i][31:16]; @(posedge clk);
            data_in <= pixel_data_mem[i][47:32]; @(posedge clk);
            data_in <= pixel_data_mem[i][63:48]; @(posedge clk);
        end
        
        // 將資料線歸零保持乾淨
        data_in <= 16'd0; 
        
        wait(uut.is_initialized == 1'b1);
        $display("[TB] Phase 1: SRAM Loading Done.");
        #(CLK_PERIOD * 20);

        // -------------------------------------------------------
        // Phase 2: ST_WORK (MNIST Inference & Learning)
        // -------------------------------------------------------
        $display("\n=== Phase 2: ST_WORK (Inference & STDP) ===");
        
        // 載入 MNIST 測試圖 (假設只有 1 張圖)
        // 註: 如果有多張圖，這個 $readmemh 應該放在 for 迴圈內，並配合動態檔名
        $readmemh("../../data/mnist_input.hex", pixel_data_mem);

        // 模擬連續送 10 次圖，觀察 STDP 權重收斂狀態
        for (frame = 1; frame <= 10; frame = frame + 1) begin
            $display("--- Start Frame %0d ---", frame);
            
            // 提早發送 Start 脈衝
            @(posedge clk);
            start_loading <= 1'b1; 
            
            @(posedge clk);
            start_loading <= 1'b0; 

            fork
                // [執行緒 1] 數據餵入迴圈 (每 4 拍一組 64-bit)
                begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        data_in <= pixel_data_mem[i][15:0];  @(posedge clk);
                        data_in <= pixel_data_mem[i][31:16]; @(posedge clk);
                        data_in <= pixel_data_mem[i][47:32]; @(posedge clk);
                        data_in <= pixel_data_mem[i][63:48]; @(posedge clk);
                    end
                    data_in <= 16'd0; // 餵完後歸零
                end
                
                // [執行緒 2] 監控結算訊號與 Timeout (時間放寬以容納雙階段)
                begin
                    wait_timeout = 0;
                    // Phase 1 (392拍) + Phase 2 (392拍) + Buffer時間，大約 800 拍
                    while (finish == 0 && wait_timeout < 2000) begin
                        @(posedge clk);
                        wait_timeout = wait_timeout + 1;
                    end
                end
            join

            if (wait_timeout >= 2000) begin
                $display("❌ [Error] Frame %0d stuck! Timeout reached.", frame);
                $finish;
            end else begin
                $display("✅ Frame %0d Finished successfully.", frame);
            end

            // Frame 之間的休息時間
            #(CLK_PERIOD * 50);
        end

        $display("\n=== Simulation Complete ===");
        $finish;
    end

    // --- 產生 FSDB 波形檔 ---
    initial begin
        $fsdbDumpfile("top_tb.fsdb");
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA;
    end

endmodule
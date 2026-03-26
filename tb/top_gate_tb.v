`timescale 1ns/1ps

// 定義 SDF 檔案路徑 (請依據你的實際路徑修改)
`define SDFFILE "./top_syn.sdf"

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
    integer file_out;
    reg [8*50:1] filename;

    // --- 實例化 DUT ---
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start_loading(start_loading),
        .addr_in(addr_in),
        .data_in(data_in),
        .spike_out(spike_out),
        .busy(busy),
        .finish(finish)
    );

    // =======================================================
    // 🌟 Gate-Level Simulation 專用：載入 SDF 延遲檔
    // =======================================================
    initial begin
`ifdef SDF
        $display("--------------------------------------------------");
        $display("[GLS] Start SDF Annotation...");
        // 語法: $sdf_annotate("sdf檔案路徑", 頂層實例名稱);
        $sdf_annotate(`SDFFILE, uut);
        $display("[GLS] SDF Annotated Successfully!");
        $display("--------------------------------------------------");
`endif
    end

    // --- 時脈產生 ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =======================================================
    // 監控區 (FSM 追蹤) - ⚠️ GLS 時自動遮蔽，因為內部變數已被優化
    // =======================================================
`ifndef SDF
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
`endif

    // =======================================================
    // 主測試流程
    // =======================================================
    initial begin
        // 0. 初始化數據
        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            pixel_data_mem[i] ={ 8{8'h20} };
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
        
        @(posedge clk);
        start_loading <= 1'b1;
        
        @(posedge clk);
        start_loading <= 1'b0; 

        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            data_in <= pixel_data_mem[i][15:0];  @(posedge clk); 
            data_in <= pixel_data_mem[i][31:16]; @(posedge clk);
            data_in <= pixel_data_mem[i][47:32]; @(posedge clk);
            data_in <= pixel_data_mem[i][63:48]; @(posedge clk);
        end
        data_in <= 16'd0; 
        
        // ⚠️ GLS 時無法偷看 is_initialized，改用觀察 busy 或等待固定時間
`ifdef SDF
        // GLS 替代方案：等待 10 個 Clock 確保資料寫完
        #(CLK_PERIOD * 10);
`else
        wait(uut.is_initialized == 1'b1);
`endif

        $display("[TB] Phase 1: SRAM Loading Done.");
        #(CLK_PERIOD * 20);

        // -------------------------------------------------------
        // Phase 2: ST_WORK (MNIST Inference & Learning)
        // -------------------------------------------------------
        $display("\n=== Phase 2: ST_WORK (Inference & STDP) ===");
        $readmemh("../data/mnist_input_7.hex", pixel_data_mem);

        for (frame = 1; frame <= 25; frame = frame + 1) begin
            $display("--- Start Frame %0d ---", frame);
            
            @(posedge clk);
            start_loading <= 1'b1; 
            @(posedge clk);
            start_loading <= 1'b0; 

            fork
                begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        data_in <= pixel_data_mem[i][15:0];  @(posedge clk);
                        data_in <= pixel_data_mem[i][31:16]; @(posedge clk);
                        data_in <= pixel_data_mem[i][47:32]; @(posedge clk);
                        data_in <= pixel_data_mem[i][63:48]; @(posedge clk);
                    end
                    data_in <= 16'd0; 
                end
                
                begin
                    wait_timeout = 0;
                    while (finish == 0 && wait_timeout < 2000) begin
                        @(posedge clk);
                        wait_timeout = wait_timeout + 1;
                    end
                end
            join

            if (wait_timeout >= 2000) begin
                $display("[Error] Frame %0d stuck! Timeout reached.", frame);
                $finish;
            end else begin
                $display("Frame %0d Finished successfully.", frame);
            end

            // ⚠️ GLS 時實體 SRAM 無法用 .mem 匯出資料，自動遮蔽
`ifndef SDF
            if (frame % 5 == 0) begin
                $sformat(filename, "weights_frame_%0d.txt", frame);
                file_out = $fopen(filename, "w");
                if (file_out) begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        $fdisplay(file_out, "%h", uut.u_we.u_sram.mem[i][63:0]); 
                    end
                    $fclose(file_out);
                    $display("Weights exported to '%0s' successfully.", filename);
                end else begin
                    $display("[Error] Could not open file for writing.");
                end
            end
`endif
            #(CLK_PERIOD * 50);
        end
        
`ifndef SDF
        $display("\n=== Exporting Final Weights to TXT ===");
        file_out = $fopen("final_weights_frame25.txt", "w");
        if (file_out) begin
            for (i = 0; i < BATCH_NUM; i = i + 1) begin
                $fdisplay(file_out, "%h", uut.u_we.u_sram.mem[i][63:0]); 
            end
            $fclose(file_out);
            $display("Weights exported to 'final_weights_frame25.txt' successfully.");
        end else begin
            $display("[Error] Could not open file for writing.");
        end
`else
        $display("\n=== [GLS] Simulation Complete (Weight Export Disabled) ===");
`endif
        
        $finish;
    end

    // --- 產生 FSDB 波形檔 ---
initial begin
        $fsdbDumpfile("top_gate_tb.fsdb");
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA;
    end

endmodule
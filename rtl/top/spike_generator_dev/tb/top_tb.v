`timescale 1ns/1ps

module top_tb;

    // Parameters
    parameter D_WIDTH   = 8;
    parameter BATCH_NUM = 98;
    parameter CLK_PERIOD = 10; // 100MHz

    // Inputs
    reg clk;
    reg rst_n;
    reg test_mode;
    reg start;
    reg accumulate_en;
    reg [15:0] data_in;

    // Outputs
    wire [7:0] spike_data;
    wire       valid;
    wire       busy;
    wire       done;

    // 宣告 98 筆 64-bit 的記憶體來接 Hex 檔
    reg [63:0] img_data [0:97];
    reg [63:0] current_row; // 暫存目前這一行的 64-bit 資料

    // ---------------------------------------------------------
    // 檔案輸出相關宣告
    // ---------------------------------------------------------
    integer file_handle;     // 檔案指標
    reg     file_open_flag;  // 控制何時允許寫入檔案的旗標
    integer i, j, t;         // 迴圈計數器

    // Instantiate the Unit Under Test (UUT)
    top #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .test_mode(test_mode),
        .start(start),
        .accumulate_en(accumulate_en),
        .data_in(data_in),
        .spike_data(spike_data),
        .valid(valid),
        .busy(busy),
        .done(done)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Verdi FSDB Dump
    initial begin
        $fsdbDumpfile("top_tb.fsdb");
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA; // 將陣列/Memory內容也 dump 出來方便在 Verdi 除錯
    end

    // ---------------------------------------------------------
    // 自動脈衝紀錄區塊 (與主流程並行)
    // ---------------------------------------------------------
    // 當檔案開啟旗標為高，且硬體舉起 valid 時，自動將脈衝狀態寫入當前文字檔
    always @(posedge clk) begin
        if (file_open_flag && valid) begin
            // 格式：二進位呈現 8 顆神經元狀態 (e.g. 00010000) 與當下的模擬時間
            $fwrite(file_handle, "Time: %0d ns | Spike State (7:0): %b\n", $time, spike_data);
        end
    end

    // ---------------------------------------------------------
    // 主測試流程 (Stimulus Process)
    // ---------------------------------------------------------
    initial begin
        // 1. 初始化輸入
        rst_n = 0;
        test_mode = 0;
        start = 0;
        accumulate_en = 0;
        data_in = 16'd0;
        file_open_flag = 0;
        $readmemh("../data/mnist_input_7.hex", img_data);
        $display("Image data loaded.");
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);
        $display("[%0t] Phase 1: Clear SRAM Started", $time);
        @(negedge clk);
        start = 1;
        accumulate_en = 0;
        @(negedge clk);
        start = 0;
        wait(uut.u_generator.sram_finish == 1'b1); 
        #(CLK_PERIOD * 5);
        $display("[%0t] Phase 1: Clear SRAM Completed", $time);
        for (t = 0; t < 10; t = t + 1) begin
            $display("[%0t] Phase 2: Round %0d Started", $time, t+1);
            file_handle = $fopen($sformatf("../output/turn%0d.txt", t+1), "w");
            $fwrite(file_handle, "=== MNIST Image Spike Results - Round %0d ===\n", t+1);
            file_open_flag = 1;
            @(negedge clk);
            start = 1;
            accumulate_en = 1;
            @(negedge clk);
            start = 0;
            for (i = 0; i < BATCH_NUM; i = i + 1) begin
                current_row = img_data[i];
                for (j = 0; j < 4; j = j + 1) begin
                    data_in = current_row[15:0];
                    current_row = current_row >> 16;
                    @(negedge clk);
                end
            end
            data_in = 16'd0;
            wait(done == 1'b1);
            #(CLK_PERIOD * 2); 
            file_open_flag = 0;
            $fclose(file_handle);
            #(CLK_PERIOD * 5);
            $display("[%0t] Phase 2: Round %0d Completed and Saved.", $time, t+1);
        end
        #(CLK_PERIOD * 10);
        $display("[%0t] All 10 Rounds Finished Successfully!", $time);
        $finish;
    end

endmodule
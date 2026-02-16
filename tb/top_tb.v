`timescale 1ns/1ps

module top_tb;

    // --- 參數定義 ---
    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98; 

    // --- 訊號宣告 ---
    reg         clk;
    reg         rst_n;
    reg         start_loading;
    reg  [6:0]  addr_in;
    reg  [15:0] data_in;
    
    wire        spike_out;
    wire        busy;
    wire        finish;

    // --- 像素資料記憶體 (用來讀取 hex 文件) ---
    reg [63:0] pixel_data_mem [0:97];
    reg [63:0] current_pixel_batch;

    // --- 實例化頂層模組 ---
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

    integer i, round;

    // --- 測試程序 ---
    initial begin
        // 0. 載入 MNIST 像素資料文件
        $readmemh("/home/t112830022/synaptic-core-asic/data/mnist_input.hex", pixel_data_mem);
        
        // 1. 系統重置
        $display("System Reset...");
        start_loading = 0;
        rst_n = 0;
        addr_in = 0;
        data_in = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // 2. 第一階段：Mode 01 載入初始權重 (只做一次)
        $display("Round 1: Mode 01 - Loading Initial Weights...");
        @(posedge clk);
        start_loading = 1;
        @(posedge clk);
        start_loading = 0;

        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            addr_in = i[6:0];
            // 這裡模擬餵入初始權重，例如 16'h1111, 2222...
            data_in = 16'h1111; #(CLK_PERIOD);
            data_in = 16'h2222; #(CLK_PERIOD);
            data_in = 16'h3333; #(CLK_PERIOD);
            data_in = 16'h4444; #(CLK_PERIOD);
        end
        
        // 等待第一輪運算結束 (Mode 10 會接著 Mode 01 自動啟動)
        // 注意：第一輪 Mode 10 因為沒餵像素，Trace 可能是 0，這是正常的
        wait(finish == 1);
        #(CLK_PERIOD * 10);

        // 3. 第二階段：連續學習 (重複執行 Mode 10)
        // 從這輪開始，我們真正餵入 mnist_input.hex 的像素
 	for (round = 2; round <= 3; round = round + 1) begin
            $display("Round %0d: Mode 10 - Feeding Pixels & Learning...", round);
            
            #(CLK_PERIOD * 5);
            @(posedge clk);
            start_loading = 1;
            @(posedge clk);
            start_loading = 0; 

            fork
                // 程序 A：負責餵資料 (總共 392 拍)
                begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        current_pixel_batch = pixel_data_mem[i];
                        data_in = current_pixel_batch[15:0];  #(CLK_PERIOD);
                        data_in = current_pixel_batch[31:16]; #(CLK_PERIOD);
                        data_in = current_pixel_batch[47:32]; #(CLK_PERIOD);
                        data_in = current_pixel_batch[63:48]; #(CLK_PERIOD);
                    end
                end
                // 程序 B：負責監控 finish 脈衝
                begin
                    @(posedge finish); // 改用邊緣觸發，更安全
                end
            join

            $display("Round %0d Finished. Weight evolution check point.", round);
            #(CLK_PERIOD * 20);
        end

        $display("Simulation Done.");
        $finish;
    end

    // --- 波形產生 ---
    initial begin
        $fsdbDumpfile("top_tb.fsdb");
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA; // 記得加上這個才能看 SRAM 陣列
    end

endmodule

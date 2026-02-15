`timescale 1ns/1ps

module top_tb;

    // --- 參數定義 ---
    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98; // 對應 98 組 64-bit 

    // --- 訊號宣告 ---
    reg         clk;
    reg         rst_n;
    reg  [1:0]  mode_sel;
    reg  [6:0]  addr_in;
    reg  [7:0]  mask_in;
    reg  [15:0] data_in;
    
    wire        spike_out;
    wire        busy;
    wire        finish;

    // --- 實例化頂層模組 (top.v) ---
    top #(
        .D_WIDTH(D_WIDTH),
        .BATCH_NUM(BATCH_NUM),
        .ADDR_WIDTH(7),
        .V_WIDTH(19),
        .T_WIDTH(8),
        .THRESHOLD(800)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .mode_sel(mode_sel),
        .addr_in(addr_in),
        .mask_in(mask_in),
        .data_in(data_in),
        .spike_out(spike_out),
        .busy(busy),
        .finish(finish)
    );

    // --- 時脈產生 ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    integer i;

    // --- 測試程序 ---
    initial begin
        // 1. 初始化
        rst_n = 0;
        mode_sel = 2'b00;
        addr_in = 0;
        mask_in = 8'hFF;
        data_in = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // 2. Mode 01: 載入 98 組基礎權重到 SRAM (0~97)
        // 為了讓波形有數值變化，給予規律的初始權重
        $display("Status: Starting Mode 01 - Full Data Loading (98 Batches)...");
        mode_sel = 2'b01;
        
        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            addr_in = i[6:0];
            // 每個 Addr 輸入四次 16-bit 以組成 64-bit 
            data_in = 16'h1111; #(CLK_PERIOD);
            data_in = 16'h2222; #(CLK_PERIOD);
            data_in = 16'h3333; #(CLK_PERIOD);
            data_in = 16'h4444; #(CLK_PERIOD);
        end
        
        mode_sel = 2'b00;
        #(CLK_PERIOD * 10);

        // 3. Mode 10: 執行推論與學習
        $display("Status: Starting Mode 10 - Inference & Learning...");
        mode_sel = 2'b10;
        
        // 等待運算完成 (finish 由 L1_done 驅動) 
        wait(finish == 1);
        #(CLK_PERIOD * 20);
        
        $display("Status: Simulation Finished!");
        $finish;
    end

    // --- 波形產生 (Verdi/VCS) ---
    initial begin
        $fsdbDumpfile("top_tb.fsdb"); // 確保與執行腳本預期名稱一致
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA; 
    end

endmodule

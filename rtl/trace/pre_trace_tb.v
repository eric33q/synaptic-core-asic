`timescale 1ns/1ps

module pre_trace_sipo_tb;

    parameter T_WIDTH     = 8;
    parameter DECAY_SHIFT = 2;
    parameter BATCH_SIZE  = 8;
    
    // 為了模擬方便，我們只測 64 個輸入 (8 個 Batch)
    // 實際使用時可以是 784
    parameter INPUT_NUM   = 64; 
    parameter BATCH_COUNT = INPUT_NUM / BATCH_SIZE; // 64/8 = 8 batches

    reg clk;
    reg rst_n;
    
    // 模擬 Layer 1 的輸出訊號
    reg                   cmd_start;
    reg                   cmd_finish;
    reg [BATCH_SIZE-1:0]  serial_spike_in;
    reg [6:0]             batch_addr;
    reg                   spike_valid;

    // DUT 輸出
    wire [INPUT_NUM*T_WIDTH-1:0] trace_out_flat;
    
    // 觀察用的拆解訊號 (Ch0 和 Ch1)
    wire [T_WIDTH-1:0] trace_ch0;
    wire [T_WIDTH-1:0] trace_ch1;
    
    assign trace_ch0 = trace_out_flat[7:0];
    assign trace_ch1 = trace_out_flat[15:8];

    // 實例化 DUT 
    pre_trace #(
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT),
        .INPUT_NUM(INPUT_NUM),    // 覆蓋為 64 以便測試
        .BATCH_SIZE(BATCH_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_start(cmd_start),
        .cmd_finish(cmd_finish),
        .serial_spike_in(serial_spike_in),
        .batch_addr(batch_addr),
        .spike_valid(spike_valid),
        .STDP_trace_out(trace_out_flat)
    );
    always #5 clk = ~clk;

    // 任務：模擬 Layer 1 發送一張圖片的過程
    // 輸入參數：target_pixel_idx -> 指定哪個像素要亮 (其他全暗)
    // 若 target_pixel_idx = -1，代表全黑 (只做衰減用)
    task send_one_frame(input integer target_pixel_idx);
        integer b;
        begin
            // 1. Start
            @(posedge clk);
            cmd_start = 1;
            @(posedge clk);
            cmd_start = 0;

            // 2. 傳送所有 Batches
            for (b = 0; b < BATCH_COUNT; b = b + 1) begin
                @(posedge clk);
                spike_valid = 1;
                batch_addr  = b;
                
                // 判斷這一批是否包含目標像素
                if (target_pixel_idx >= (b * 8) && target_pixel_idx < ((b + 1) * 8)) begin
                    // 產生 One-hot 編碼 (例如 idx=0 -> 00000001)
                    serial_spike_in = 1 << (target_pixel_idx % 8); 
                end else begin
                    serial_spike_in = 8'd0;
                end
            end
            
            // 結束傳送
            @(posedge clk);
            spike_valid = 0;
            serial_spike_in = 0;

            // 3. Finish (觸發 Trace 更新!)
            @(posedge clk);
            cmd_finish = 1;
            @(posedge clk);
            cmd_finish = 0;
            repeat(5) @(posedge clk);
        end
    endtask

    // ==========================================
    // 測試流程
    // ==========================================
    initial begin
        $fsdbDumpfile("pre_trace_sipo.fsdb");
        $fsdbDumpvars(0, pre_trace_sipo_tb, "+all");

        // 初始化
        clk = 0; rst_n = 0;
        cmd_start = 0; cmd_finish = 0;
        serial_spike_in = 0; batch_addr = 0; spike_valid = 0;

        $display("--- [Time 0] System Reset ---");
        #20 rst_n = 1;
        #20;

        // --------------------------------------------------------
        // Case 1: Single Spike on Ch0 (單一脈衝)
        // --------------------------------------------------------
        $display("--- [Time %t] Case 1: Fire Pixel 0 ---", $time);
        // 發送第一張圖，只有 Pixel 0 是亮的
        send_one_frame(0); 
        // 預期結果：trace_ch0 應該變成 255
        
        $display("--- [Time %t] Case 1: Decay Phase ---", $time);
        // 發送第二張圖，全黑 (模擬時間流逝)
        send_one_frame(-1); 
        // 預期結果：trace_ch0 應該衰減 (255 -> 191)

        send_one_frame(-1); 
        // 預期結果：繼續衰減 (191 -> 143)

        // --------------------------------------------------------
        // Case 2: Refresh Test on Ch1 (刷新測試)
        // --------------------------------------------------------
        $display("--- [Time %t] Case 2: Fire Pixel 1 ---", $time);
        send_one_frame(1);
        // 預期：Ch1 = 255

        $display("--- [Time %t] Decay... ---", $time);
        send_one_frame(-1); // Decay 1
        send_one_frame(-1); // Decay 2
        // 預期：Ch1 變小

        $display("--- [Time %t] Refire Pixel 1! ---", $time);
        send_one_frame(1);
        // 預期：Ch1 彈回 255

        $display("--- Simulation Done ---");
        $finish;
    end

    // Monitor
    always @(posedge clk) begin
        // 只在 Trace 數值發生變化 (通常是 cmd_finish 後) 印出
        if (cmd_finish) begin
            // 延遲一點點讀取更新後的值
            #1; 
            $display("Time %t | [Update Event] Ch0: %3d | Ch1: %3d", 
                     $time, trace_ch0, trace_ch1);
        end
    end

endmodule
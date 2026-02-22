`timescale 1ns/1ps

module top_tb;

    parameter CLK_PERIOD = 10;
    parameter D_WIDTH    = 8;
    parameter BATCH_NUM  = 98; 

    reg         clk;
    reg         rst_n;
    reg         start_loading;
    reg  [6:0]  addr_in;
    reg  [15:0] data_in;
    reg  [63:0] pixel_data_in; 
    
    wire [6:0]  req_addr_out;  
    wire        spike_out;
    wire        busy;
    wire        finish;

    reg [63:0] pixel_data_mem [0:97];
    reg [63:0] current_pixel_batch;
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

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // 模擬 ROM 行為
    always @(posedge clk) begin
        if (!rst_n) pixel_data_in <= 64'd0;
        else        pixel_data_in <= pixel_data_mem[req_addr_out];
    end

    // =======================================================
    // 🚨 Debug 監控區 (這會自動印出 FSM 的一舉一動)
    // =======================================================
    
    // 1. 監聽 Top FSM 的狀態切換
    always @(uut.current_mode) begin
        case (uut.current_mode)
            2'b00: $display("[FSM Tracker] T=%7t | Top entered ST_IDLE", $time);
            2'b01: $display("[FSM Tracker] T=%7t | Top entered ST_LOAD", $time);
            2'b10: $display("[FSM Tracker] T=%7t | Top entered ST_WORK", $time);
            2'b11: $display("[FSM Tracker] T=%7t | Top entered ST_FINISH", $time);
        endcase
    end

    // 2. 監聽 Spike Generator 吐出的 finish 訊號
    always @(posedge finish) begin
        $display("[Pulse Tracker] T=%7t | Spike Generator fired 'finish'!", $time);
    end

    // 3. 看門狗 (Watchdog Timer) - 防止無限卡死
    initial begin
        #(CLK_PERIOD * 50000); // 如果模擬超過 500,000 ns 還沒結束，強制中斷
        $display("\n=======================================================");
        $display(" ❌ ERROR: WATCHDOG TIMEOUT! SIMULATION HUNG! ");
        $display("=======================================================\n");
        $finish;
    end

    integer i, frame;
    integer wait_timeout;

    // =======================================================
    // 主測試流程
    // =======================================================
    initial begin
        $readmemh("../../data/mnist_input.hex", pixel_data_mem);
        
        $display("\n=== System Reset ===");
        start_loading = 0;
        rst_n = 0;
        addr_in = 0;
        data_in = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // --- Phase 1 ---
        $display("\n=== Phase 1: Initialization ===");
        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            @(posedge clk);
            start_loading = 1;
            addr_in = #1 i[6:0];
            data_in = #1 16'h1111;
            @(posedge clk); data_in = #2 16'h2222; 
            @(posedge clk); data_in = #1 16'h3333; 
            @(posedge clk); data_in = #1 16'h4444; 
        end
        
        @(posedge clk);
        start_loading = #1 0;
        
        // 【重要】這裡「不要」加 wait(finish == 1)，因為 ST_LOAD 不會產生 finish
        $display("[TB] Phase 1 loop ended, waiting 10 clocks...");
        #(CLK_PERIOD * 10);

        // =======================================================
        // 3. Phase 2: Learning & Inference
        // =======================================================
        $display("\n=== Phase 2: Learning & Inference ===");
        
        for (frame = 1; frame <= 6; frame = frame + 1) begin
            $display("--- Start Frame %0d ---", frame);
            
            #(CLK_PERIOD * 5);
            @(posedge clk);
            start_loading = #1 1; 
            @(posedge clk);
            start_loading = #1 0; 

            // 因為現在是 Option A，我們必須在這裡負責每 4 拍餵 64-bit
            fork
                begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        current_pixel_batch = pixel_data_mem[i];
                        data_in = current_pixel_batch[15:0];  #(CLK_PERIOD);
                        data_in = current_pixel_batch[31:16]; #(CLK_PERIOD);
                        data_in = current_pixel_batch[47:32]; #(CLK_PERIOD);
                        data_in = current_pixel_batch[63:48]; #(CLK_PERIOD);
                    end
                end
                
                // 監控 finish 訊號
                begin
                    wait_timeout = 0;
                    while (finish == 0 && wait_timeout < 600) begin // 時間放寬，因為 1 個 Frame 變 392 拍了
                        @(posedge clk);
                        wait_timeout = wait_timeout + 1;
                    end
                end
            join

            if (wait_timeout >= 600) $display("❌ [Error] Frame %0d stuck!", frame);
            else                     $display("✅ Frame %0d Finished.", frame);

            #(CLK_PERIOD * 10);
        end

        $display("\n=== Simulation Done ===");
        $finish;
    end

    initial begin
        $fsdbDumpfile("top_tb.fsdb");
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA;
    end

endmodule
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
            2'b00: $display("[FSM] T=%7t | ST_IDLE", $time);
            2'b01: $display("[FSM] T=%7t | ST_LOAD", $time);
            2'b10: $display("[FSM] T=%7t | ST_WORK", $time);
            2'b11: $display("[FSM] T=%7t | ST_FINISH", $time);
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
        // Phase 1: ST_LOAD (載入位址特徵權重)
        // -------------------------------------------------------
        $display("\n=== Phase 1: ST_LOAD (Weight Initialization) ===");
        for (i = 0; i < BATCH_NUM; i = i + 1) begin
            @(posedge clk);
            start_loading = 1;
            addr_in = i[6:0];
            
            // 餵入 4 拍 16-bit 片段
            data_in = #1 pixel_data_mem[i][15:0];  @(posedge clk); start_loading = 0;
            data_in = #1 pixel_data_mem[i][31:16]; @(posedge clk);
            data_in = #1 pixel_data_mem[i][47:32]; @(posedge clk);
            data_in = #1 pixel_data_mem[i][63:48]; 
        end
        
        wait(uut.is_initialized == 1'b1);
        $display("[TB] Phase 1: SRAM Loading Done.");
        #(CLK_PERIOD * 20);

        // -------------------------------------------------------
        // Phase 2: ST_WORK (MNIST Inference)
        // -------------------------------------------------------
        $display("\n=== Phase 2: ST_WORK (Inference) ===");
        // MNIST data
        $readmemh("../../data/mnist_input.hex", pixel_data_mem);

        for (frame = 1; frame <= 3; frame = frame + 1) begin
            $display("--- Frame %0d ---", frame);
            
            @(posedge clk);
            start_loading = #1 1; 
            @(posedge clk);
            start_loading = #1 0; 

            // 數據餵入迴圈 (每 4 拍一組 64-bit)
            fork
                begin
                    for (i = 0; i < BATCH_NUM; i = i + 1) begin
                        data_in = #1 pixel_data_mem[i][15:0];  @(posedge clk);
                        data_in = #1 pixel_data_mem[i][31:16]; @(posedge clk);
                        data_in = #1 pixel_data_mem[i][47:32]; @(posedge clk);
                        data_in = #1 pixel_data_mem[i][63:48]; @(posedge clk);
                    end
                end
                
                begin
                    wait_timeout = 0;
                    while (finish == 0 && wait_timeout < 1000) begin
                        @(posedge clk);
                        wait_timeout = wait_timeout + 1;
                    end
                end
            join

            if (wait_timeout >= 1000) begin
                $display("[Error] Frame %0d stuck!", frame);
                $finish;
            end else begin
                $display("Frame %0d Finished.", frame);
            end

            #(CLK_PERIOD * 50);
        end

        $display("\n=== Simulation Complete ===");
        $finish;
    end

    initial begin
        $fsdbDumpfile("top_tb.fsdb");
        $fsdbDumpvars(0, top_tb);
        $fsdbDumpMDA;
    end

endmodule

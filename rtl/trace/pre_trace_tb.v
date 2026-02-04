`timescale 1ns/1ps

module pre_trace_tb;

    parameter T_WIDTH     = 8;      // Trace 位寬 (0~255)
    parameter DECAY_SHIFT = 2;      // 衰減速度 (數值越小衰減越快)
    parameter ADD_VAL     = 8'd64;  // 每個 Spike 增加的數值
    parameter INPUT_NUM   = 64;     // 通道數量
    reg                     clk;
    reg                     rst_n;
    reg  [INPUT_NUM-1:0]    spike_in;       // 模擬輸入脈衝
    wire [INPUT_NUM*T_WIDTH-1:0] trace_out_flat; // DUT 輸出
    wire [T_WIDTH-1:0] trace_ch0;
    wire [T_WIDTH-1:0] trace_ch1;
    
    assign trace_ch0 = trace_out_flat[7:0];
    assign trace_ch1 = trace_out_flat[15:8];

    pre_trace #(
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT),
        .ADD_VAL(ADD_VAL),
        .INPUT_NUM(INPUT_NUM)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .spike_in(spike_in),
        .trace_out_flat(trace_out_flat)
    );

    always #5 clk = ~clk;

    initial begin
        $fsdbDumpfile("pre_trace.fsdb");
        $fsdbDumpvars(0, pre_trace_tb, "+all");
    
        clk = 0;
        rst_n = 0;
        spike_in = 0;
        $display("--- [Time 0] System Reset ---");
        #20 rst_n = 1;
        #10;

   
        // Single Spike
        $display("--- [Time %t] Case 1: Single Spike on Ch0 ---", $time);
        @(posedge clk);
        spike_in[0] = 1;  // 發射脈衝！
        @(posedge clk);
        spike_in[0] = 0;  // 停止
        repeat(20) @(posedge clk);

        // Accumulation
        $display("--- [Time %t] Case 2: Consecutive Spikes on Ch1 ---", $time);
        @(posedge clk);
        spike_in[1] = 1; // 第 1 發
        @(posedge clk);
        spike_in[1] = 0;
        repeat(3) @(posedge clk); // 稍微等一下 (還沒衰減完)
        spike_in[1] = 1; // 第 2 發 (應該要在殘值上往上加)
        @(posedge clk);
        spike_in[1] = 0;
        repeat(20) @(posedge clk);

        // Saturation
        $display("--- [Time %t] Case 3: Saturation Test on Ch0 ---", $time);
        repeat(6) begin
            @(posedge clk);
            spike_in[0] = 1;
        end
        spike_in[0] = 0; // 停火
        repeat(20) @(posedge clk);

      
        $display("--- Simulation Done ---");
        $finish;
    end

    //  Monitor
    always @(posedge clk) begin
        if (trace_ch0 > 0 || trace_ch1 > 0) begin
            $display("Time %t | Ch0 Trace: %3d | Ch1 Trace: %3d | Input: %b", 
                      $time, trace_ch0, trace_ch1, spike_in[1:0]);
        end
    end

endmodule
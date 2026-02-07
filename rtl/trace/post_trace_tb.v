`timescale 1ns/1ps

module post_trace_tb;

    // 參數設定：只測 1 顆
    parameter NUM_POST    = 1;
    parameter T_WIDTH     = 8;
    parameter DECAY_SHIFT = 2;

    // 訊號宣告
    reg                     clk;
    reg                     rst_n;
    reg  [NUM_POST-1:0]     fire_in; // 這是 1-bit [0:0]
    wire [NUM_POST*T_WIDTH-1:0] trace_out_flat; // 這是 8-bit [7:0]

    // 實例化 DUT
    post_trace #(
        .NUM_POST(NUM_POST),
        .T_WIDTH(T_WIDTH),
        .DECAY_SHIFT(DECAY_SHIFT)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .fire_in(fire_in),
        .trace_out_flat(trace_out_flat)
    );

    // 時脈產生
    always #5 clk = ~clk;

    // 測試流程
    initial begin
        $fsdbDumpfile("post_trace.fsdb");
        $fsdbDumpvars(0, post_trace_tb, "+all");

        // 1. 初始化
        clk = 0; rst_n = 0; fire_in = 0;
        #20 rst_n = 1;
        #20;

        // 2. 測試情境 A: 神經元發火 (Fire)
        $display("Time %t: Neuron Fired!", $time);
        @(posedge clk);
        fire_in[0] = 1;  // 拉高
        @(posedge clk);
        fire_in[0] = 0;  // 拉低

        // 預期：Trace 值應該瞬間變成 255

        // 3. 測試情境 B: 觀察自然衰減 (Decay)
        $display("Time %t: Observing Decay...", $time);
        repeat(10) @(posedge clk); 
        
        // 預期：Trace 值應該慢慢變小 (255 -> 191 -> 143 ...)

        // 4. 測試情境 C: 再次發火
        $display("Time %t: Neuron Fired Again!", $time);
        @(posedge clk);
        fire_in[0] = 1;
        @(posedge clk);
        fire_in[0] = 0;

        repeat(10) @(posedge clk);

        $display("Simulation Done");
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        // 只要數值有變動就印出來
        if (fire_in[0] || trace_out_flat > 0) begin
             $display("Time %t | Fire: %b | Trace: %3d", 
                      $time, fire_in[0], trace_out_flat);
        end
    end

endmodule
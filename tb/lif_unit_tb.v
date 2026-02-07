`timescale 1ns/1ps

module lif_unit_tb;
    // Parameters
    parameter D_WIDTH    = 8;
    parameter I_WIDTH    = 18;
    parameter V_WIDTH    = 19;
    parameter THRESHOLD  = 800;
    parameter LEAK_SHIFT = 3;
    parameter REF_PERIOD = 3;

    // Inputs
    reg clk;
    reg rst_n;
    reg [63:0] weight_mem;

    // Outputs
    wire post_spike;
    wire [V_WIDTH-1:0] V_mem_out;

    // 實例化 DUT
    lif_unit_784to1 #(
        .D_WIDTH(D_WIDTH),
        .I_WIDTH(I_WIDTH),
        .V_WIDTH(V_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_SHIFT(LEAK_SHIFT),
        .REF_PERIOD(REF_PERIOD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_mem(weight_mem),
        .post_spike(post_spike),
        .V_mem_out(V_mem_out)
    );

    // 時脈：10ns (100MHz)
    always #5 clk = ~clk;

    // 模擬一組 784 個輸入的任務 (Task)
    task feed_784_weights;
        input [7:0] val; // 假設每個權重都設為同一個值
        integer i;
        begin
            for (i = 0; i < 98; i = i + 1) begin
                @(posedge clk);
                weight_mem = {8{val}}; // 每次餵入 8 個權重
            end
            // 餵完 98 組後，清空輸入等待處理
            @(posedge clk);
            weight_mem = 64'h0;
        end
    endtask

    initial begin
        // --- NC-Verilog / Verdi FSDB Dump ---
        // 確保環境變數有設好，否則 NC-Verilog 可能報錯找不到此系統函數
        $fsdbDumpfile("lif_unit_tb.fsdb");
        $fsdbDumpvars(0, lif_unit_tb);
        $fsdbDumpMDA; // 傾倒多維陣列（如模組內部的 weight 陣列）

        // 初始化
        clk = 0;
        rst_n = 0;
        weight_mem = 64'h0;

        // 1. 重置
        #100 rst_n = 1;
        #20;

        // 2. 第一次累積：給予較小權重 (不會發火)
        // 總和 = 784 * 1 = 784，但在積分器中會被漏電抵銷部分
        $display("Starting Cycle 1: Small weights...");
        feed_784_weights(8'd1); 
        #200;

        // 3. 第二次累積：給予較大權重 (預期觸發 Spike)
        // 總和 = 784 * 5 = 3920，遠超 THRESHOLD 200
        $display("Starting Cycle 2: Large weights to trigger spike...");
        feed_784_weights(8'd5);

        // 4. 持續觀察 Spike 產生的 Reset 與 Refractory Period
        #500;

        $display("Simulation finished. Open Verdi to check lif_sim.fsdb");
        $finish;
    end

endmodule
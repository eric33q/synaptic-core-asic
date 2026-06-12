`timescale 1ns/1ps

module top_tb_gls;

    // Parameters (在 GLS 中通常頂層參數已經被寫死成常數，這裡僅供 TB 內部迴圈使用)
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

    reg [63:0] img_data [0:97];
    reg [63:0] current_row; 
    
    integer file_handle;
    reg     file_open_flag;
    integer i, j, t;
    top uut (
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
    initial begin
        $sdf_annotate("../../syn/netlist/top_syn.sdf", uut);
        $display("SDF Annotation Completed.");
    end
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $fsdbDumpfile("top_gate_tb.fsdb");
        $fsdbDumpvars(0, top_tb_gls);
        // GLS 檔案通常極大，如果不需要看記憶體陣列，可以把 $fsdbDumpMDA 註解掉以節省硬碟空間
        // $fsdbDumpMDA; 
    end

    always @(posedge clk) begin
        if (file_open_flag && valid) begin
            $fwrite(file_handle, "Time: %0d ns | Spike State (7:0): %b\n", $time, spike_data);
        end
    end

    initial begin
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
        #(CLK_PERIOD * (BATCH_NUM + 5));
        $display("[%0t] Phase 1: Clear SRAM Completed (Wait by Cycle)", $time);
        for (t = 0; t < 10; t = t + 1) begin
            $display("[%0t] Phase 2: Round %0d Started", $time, t+1);
            
            file_handle = $fopen($sformatf("../output/gls_turn%0d.txt", t+1), "w");
            $fwrite(file_handle, "=== MNIST Image Spike Results (GLS) - Round %0d ===\n", t+1);
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
            
            // Phase 2 等待 done 訊號，因為這是合法的頂層 Output 腳位
            wait(done == 1'b1);
            
            #(CLK_PERIOD * 2); 
            
            file_open_flag = 0;
            $fclose(file_handle);
            
            #(CLK_PERIOD * 5);
            $display("[%0t] Phase 2: Round %0d Completed.", $time, t+1);
        end

        #(CLK_PERIOD * 10);
        $display("[%0t] GLS All 10 Rounds Finished Successfully!", $time);
        $finish;
    end

endmodule
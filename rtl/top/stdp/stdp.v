module stdp #(
    parameter WEIGHT_WIDTH = 8,
    parameter TRACE_WIDTH  = 8,
    parameter SHIFT_LTP    = 2, // 數值越小，LTP 增強幅度越大
    parameter SHIFT_LTD    = 3  // 數值越小，LTD 抑制幅度越大
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    // --- 觸發訊號 ---
    input  wire                    pre_spike_in,  // 來自 Layer 1 的像素脈衝
    input  wire                    post_spike_in, // 來自 Neuron 的發火訊號
    
    // --- 數據輸入 (由 SRAM 讀出與 Trace 暫存器提供) ---
    input  wire [WEIGHT_WIDTH-1:0] weight_old,    // 讀出的舊權重 (0~255)
    input  wire [TRACE_WIDTH-1:0]  pre_trace,     // 像素軌跡值 (用於計算 LTP)
    input  wire [TRACE_WIDTH-1:0]  post_trace,    // 神經元軌跡值 (用於計算 LTD)
    
    // --- 數據輸出 (接回 SRAM 寫入端) ---
    output reg  [WEIGHT_WIDTH-1:0] weight_new,    // 計算後的新權重
    output reg                     write_en       // 輸出至 wr_mask，決定是否執行 Byte 寫入
);


    // 當神經元發火時，根據之前的像素活動增加權重(LTP)
    wire [WEIGHT_WIDTH-1:0] delta_ltp = post_spike_in ? (pre_trace >> SHIFT_LTP) : 8'd0;
    
    // 當像素脈衝進來時，根據之前的神經元發火狀況減少權重(LTD)
    wire [WEIGHT_WIDTH-1:0] delta_ltd = pre_spike_in  ? (post_trace >> SHIFT_LTD) : 8'd0;

    // 淨值運算 (使用 10-bit 寬度確保加減過程不溢位)
    reg [9:0] w_temp; 

    always @(*) begin
        // 只要發生任何發火事件，就代表權重有更新需求
        write_en = post_spike_in | pre_spike_in;
        
        // 新權重 = 舊權重 + LTP - LTD
        w_temp = {2'b0, weight_old} + {2'b0, delta_ltp};
        
        // 下限保護 
        if (w_temp < {2'b0, delta_ltd}) begin
            weight_new = 8'd0;
        end else begin
            w_temp = w_temp - {2'b0, delta_ltd};
            
            // 上限保護 
            if (w_temp > 10'd255) begin
                weight_new = 8'd255;
            end else begin
                weight_new = w_temp[7:0];
            end
        end
    end

endmodule

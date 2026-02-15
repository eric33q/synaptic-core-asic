module pre_trace #(
    parameter T_WIDTH     = 8,      // Trace 位寬 (0~255)
    parameter BATCH_NUM   = 98,     // 總共有幾組 (784 / 8)
    parameter N_PARALLEL  = 8,      // 平行處理個數 (Layer 1 一次給 8 個)
    parameter ADDR_WIDTH  = 7       // ceil(log2(98)) = 7
)(
    input  wire                     clk,
    input  wire                     rst_n,
    
    // --- 來自 Layer 1 的介面 ---
    input  wire                     update_en,    // 當 Layer 1 數據有效時拉高 (Valid)
    input  wire [ADDR_WIDTH-1:0]    addr_in,      // 當前是第幾組 (0 ~ 97)
    input  wire [N_PARALLEL-1:0]    spikes_in,    // 8 bit 脈衝輸入
    
    // --- 輸出給 Layer 5 (STDP) 的介面 ---
    // 我們將 8 個 8-bit 的 trace 攤平成一條 64-bit 線傳出去
    output wire [N_PARALLEL*T_WIDTH-1:0] trace_out_flat
);

    // ============================================================
    // 1. 記憶體宣告 (Distributed RAM)
    // ============================================================
    // 雖然總量是 784 bytes，但我們以 "8 bytes (64 bits)" 為一個單位存取
    // 這樣可以一次讀寫 8 個像素的資料
    reg [N_PARALLEL*T_WIDTH-1:0] trace_mem [0:BATCH_NUM-1];

    // ============================================================
    // 2. 內部訊號
    // ============================================================
    wire [N_PARALLEL*T_WIDTH-1:0] w_old_trace_flat; // 從記憶體讀出的舊值
    wire [N_PARALLEL*T_WIDTH-1:0] w_new_trace_flat; // 算完的新值

    // [讀取操作] 非同步讀取 (Distributed RAM 特性)
    // 只要 addr_in 改變，舊資料馬上出現在 w_old_trace_flat
    assign w_old_trace_flat = trace_mem[addr_in];

    // ============================================================
    // 3. 實例化 8 個運算核心 (平行運算)
    // ============================================================
    genvar i;
    generate
        for (i = 0; i < N_PARALLEL; i = i + 1) begin : trace_cores
            
            // 實例化 trace_core (純組合邏輯版)
            trace_core #(
                .T_WIDTH(T_WIDTH)
            ) u_core (
                // 拆解 input vector: 取出第 i 個像素的 Spike
                .spike_in      (spikes_in[i]),
                
                // 拆解 input vector: 取出第 i 個像素的 Old Trace
                // 語法 [base +: width] 代表從 base 開始往上數 width 個 bit
                .trace_old_in  (w_old_trace_flat[i*T_WIDTH +: T_WIDTH]),
                
                // 組合 output vector: 將結果填入 New Trace
                .trace_new_out (w_new_trace_flat[i*T_WIDTH +: T_WIDTH])
            );
        end
    endgenerate

    // ============================================================
    // 4. 寫回邏輯 (Update Memory)
    // ============================================================
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置所有記憶體為 0
            for (j = 0; j < BATCH_NUM; j = j + 1) begin
                trace_mem[j] <= 0;
            end
        end 
        else if (update_en) begin
            // 只有當 Layer 1 數據有效時才更新
            // 將計算完的新值寫回同一個地址
            trace_mem[addr_in] <= w_new_trace_flat;
        end
    end

    // ============================================================
    // 5. 輸出給 Layer 5
    // ============================================================
    // Layer 5 需要的是 "更新後" 的 Trace 值 (也就是當下最新的狀態)
    assign trace_out_flat = w_new_trace_flat;

endmodule
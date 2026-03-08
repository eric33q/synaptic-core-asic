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
    // 1. 內部訊號
    // ============================================================
    wire [N_PARALLEL*T_WIDTH-1:0] w_old_trace_flat; // 從記憶體讀出的舊值
    wire [N_PARALLEL*T_WIDTH-1:0] w_new_trace_flat; // 算完的新值

    // ============================================================
    // 2. 管線化暫存器
    // ============================================================
    reg [ADDR_WIDTH-1:0]         addr_in_d1;
    reg                          update_en_d1;
    reg [N_PARALLEL-1:0]         spikes_in_d1;
    reg [N_PARALLEL*T_WIDTH-1:0] trace_out_d2; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_in_d1   <= 0;
            update_en_d1 <= 0;
            spikes_in_d1 <= 0;
            trace_out_d2 <= 0;
        end else begin
            // --- 第一拍延遲 --- 
            // 保存輸入訊號，提供給 SRAM 讀取舊值與後續計算新值
            addr_in_d1   <= addr_in;
            update_en_d1 <= update_en;
            spikes_in_d1 <= spikes_in;
            
            // --- 第二拍延遲 ---
            // 保存 SRAM 吐出來的舊資料，確保輸出給 STDP 時擁有精準的 2 拍延遲
            trace_out_d2 <= w_old_trace_flat; 
        end
    end

    // ============================================================
    // 3. 實例化 128x64 單埠 SRAM (取代原本的 trace_mem)
    // ============================================================
    wire sram_cen = 1'b0;          // 永遠致能 (Active Low)
    
    // 關鍵：將寫入致能訊號延遲 1 拍。
    // 等到第 1 拍算出新 Trace 後，才在下一個正緣寫回 SRAM
    wire sram_wen = ~update_en_d1; // Active Low

    sram_sp_128x64 u_trace_sram (
        .CLK  (clk),
        .CEN  (sram_cen),
        .WEN  (sram_wen),
        .BWEN (8'h00),             // 全開不遮罩 (Active Low，0 為寫入)
        .A    (addr_in_d1),        // 使用延遲 1 拍的地址
        .D    (w_new_trace_flat),  // 寫入運算後的新值
        .Q    (w_old_trace_flat)   // 讀出舊值
    );

    // ============================================================
    // 4. 實例化 8 個運算核心 (平行運算)
    // ============================================================
    genvar i;
    generate
        for (i = 0; i < N_PARALLEL; i = i + 1) begin : trace_cores
            
            // 實例化 trace_core (純組合邏輯版)
            trace_core #(
                .T_WIDTH(T_WIDTH)
            ) u_core (
                // 拿延遲 1 拍的脈衝，配上 SRAM 剛讀出來的舊資料進行計算
                .spike_in      (spikes_in_d1[i]),
                
                // 拆解 input vector: 取出第 i 個像素的 Old Trace
                // 語法 [base +: width] 代表從 base 開始往上數 width 個 bit
                .trace_old_in  (w_old_trace_flat[i*T_WIDTH +: T_WIDTH]),
                
                // 組合 output vector: 將結果填入 New Trace
                .trace_new_out (w_new_trace_flat[i*T_WIDTH +: T_WIDTH])
            );
        end
    endgenerate

    // ============================================================
    // 5. 輸出給 Layer 5
    // ============================================================
    // 輸出經過 trace_out_d2 打拍後的資料，達成完美的 2 拍讀取延遲
    assign trace_out_flat = trace_out_d2;

endmodule
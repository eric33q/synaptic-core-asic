module spike_buffer_layer1#(
    parameter INPUT_WIDTH = 8,    // Layer 1 每次給 8 bit
    parameter TOTAL_PIXELS = 784  // 總共要收集多少 bit
)(
    input  wire clk,
    input  wire rst_n,

    // --- 來自 Layer 1 的介面 (寫入端) ---
    input  wire [INPUT_WIDTH-1:0] l1_spike_data, // 8-bit 數據
    input  wire                   l1_valid,      // Layer 1 說這筆數據有效
    output reg                    buf_ready,     // Buffer 告訴 Layer 1: 我準備好收了 (Full=0)

    // --- 給 Layer 2 的介面 (讀出端) ---
    output reg [TOTAL_PIXELS-1:0] l2_full_spike_vector, // 784-bit 巨大匯流排
    output reg                    l2_valid,             // 告訴 Layer 2: 784 bits 都收集好了
    input  wire                   l2_done               // Layer 2 說: 我算完了，你可以收下一張了
);

    // 計算需要多少 bits 來當作計數器 (例如 784 需要 10 bits: 2^10=1024)
    localparam CNT_WIDTH = $clog2(TOTAL_PIXELS);

    // 內部暫存器 (這就是那個 Buffer)
    reg [TOTAL_PIXELS-1:0] buffer_mem;
    reg [CNT_WIDTH-1:0]    write_ptr; // 寫入指標 (0, 8, 16...)
    reg                    is_full;   // 狀態旗標

    // ============================================================
    // 寫入邏輯 (Serial In)
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_mem <= 0;
            write_ptr  <= 0;
            is_full    <= 0;
        end else begin
            // 狀態 1: 正在接收資料 (未滿) 且 Layer 1 送來有效資料
            if (!is_full && l1_valid) begin
                // 使用 Indexed Vector Part Select (動態寫入)
                // 語法: [base_addr +: width]
                buffer_mem[write_ptr +: INPUT_WIDTH] <= l1_spike_data;
                
                // 更新指標
                if (write_ptr + INPUT_WIDTH >= TOTAL_PIXELS) begin
                    // 填滿了！
                    is_full   <= 1;
                    write_ptr <= 0; // 重置指標
                end else begin
                    write_ptr <= write_ptr + INPUT_WIDTH;
                end
            end
            
            // 狀態 2: 已經滿了，等待 Layer 2 說 Done
            else if (is_full && l2_done) begin
                is_full <= 0; // 解除鎖定，準備接收下一批
                // write_ptr 已經在上面重置為 0 了
            end
        end
    end

    // ============================================================
    // 輸出邏輯 (Parallel Out & Handshake)
    // ============================================================
    
    // 1. 告訴 Layer 1: 只要我不滿 (is_full = 0)，你就儘管送資料來
    always @(*) begin
        buf_ready = ~is_full;
    end

    // 2. 告訴 Layer 2: 只有我滿了 (is_full = 1)，資料才有效
    always @(*) begin
        l2_valid = is_full;
        // 直接把內部記憶體拉出去
        l2_full_spike_vector = buffer_mem;
    end

endmodule
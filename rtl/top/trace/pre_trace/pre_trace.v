`timescale 1ns/1ps

module pre_trace #(
    parameter T_WIDTH     = 8,      // Trace 位寬 (0~255)
    parameter BATCH_NUM   = 98,     // 總共有幾組 (784 / 8)
    parameter N_PARALLEL  = 8,      // 平行處理個數 (Layer 1 一次給 8 個)
    parameter ADDR_WIDTH  = 7       // ceil(log2(98)) = 7
)(
    input  wire                                 clk,
    input  wire                                 rst_n,
    
    // --- 來自 Layer 1 的介面 ---
    input  wire                                 update_en,    // 當 Layer 1 數據有效時拉高 (Valid)
    input  wire [ADDR_WIDTH-1:0]                addr_in,      // 當前是第幾組 (0 ~ 97)
    input  wire [N_PARALLEL-1:0]                spikes_in,    // 8 bit 脈衝輸入
    
    // --- 輸出給 Layer 5 (STDP) 的介面 ---
    output wire [N_PARALLEL*T_WIDTH-1:0]        trace_out_flat
);

    // ============================================================
    // 1. 內部訊號
    // ============================================================
    wire [N_PARALLEL*T_WIDTH-1:0] w_old_trace_flat; // 從記憶體讀出的舊值
    wire [N_PARALLEL*T_WIDTH-1:0] w_new_trace_flat; // 算完的新值

    // ============================================================
    // 2. 管線化暫存器 (3-Stage Shift Register for Read-Modify-Write)
    // ============================================================
    reg [ADDR_WIDTH-1:0] hold_addr;
    reg [N_PARALLEL-1:0] hold_spikes;
    reg [2:0]            action_pipe; // 3拍的動作排程

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            action_pipe <= 3'd0;
            hold_addr   <= {ADDR_WIDTH{1'b0}};
            hold_spikes <= {N_PARALLEL{1'b0}};
        end else begin
            // Shift register 推動時間軸 (每個 Cycle 往左移)
            action_pipe <= {action_pipe[1:0], update_en};
            
            // Cycle 0: 在 Valid 的第一拍，將地址與輸入脈衝「死死鎖住」，供後續 3 拍使用
            if (update_en) begin
                hold_addr   <= addr_in;
                hold_spikes <= spikes_in;
            end
        end
    end

    // ============================================================
    // 3. 實例化 128x64 單埠 SRAM
    // ============================================================
    // 記憶體存取位址仲裁：
    // - Phase 1 正在更新 (|action_pipe 為 1) 時，鎖定 hold_addr 避免被外界干擾
    // - Phase 2 純讀取時，直接根據 addr_in 即時給出位址
    wire [ADDR_WIDTH-1:0] sram_addr = (|action_pipe) ? hold_addr : addr_in;

    wire sram_cen = 1'b0; // 永遠致能

    // 關鍵魔法：在 action_pipe 的第 3 拍才拉低 (發動寫入)，完美錯開讀取
    wire sram_wen = ~action_pipe[2];
    
    //暫時
    wire [6:0]  sram_addr_dly;
    wire        sram_cen_dly;
    wire        sram_wen_dly;
    wire [63:0] sram_d_dly;

    assign #1 sram_addr_dly = sram_addr;
    assign #1 sram_cen_dly  = sram_cen;
    assign #1 sram_wen_dly  = sram_wen;
    assign #1 sram_d_dly    = w_new_trace_flat; // 這裡先寫一半，剩下的會在 trace_core 裡計算好後接上

    pre_trace_mem u_trace_sram (
        .CLK  (clk),
        .CEN  (sram_cen_dly),
        .WEN  (sram_wen_dly),
        .A    (sram_addr_dly),         // 使用仲裁後的地址
        .D    (sram_d_dly),  // 寫入運算後的新值
        .Q    (w_old_trace_flat),   // 讀出舊值
        .EMA  ()
    );

    // ============================================================
    // 4. 實例化 8 個運算核心 (平行運算)
    // ============================================================
    genvar i;
    generate
        for (i = 0; i < N_PARALLEL; i = i + 1) begin : trace_cores
            trace_core #(
                .T_WIDTH(T_WIDTH)
            ) u_core (
                // 拿「鎖住的脈衝」，配上 SRAM 剛讀出來的舊資料進行計算
                .spike_in      (hold_spikes[i]),
                .trace_old_in  (w_old_trace_flat[i*T_WIDTH +: T_WIDTH]),
                .trace_new_out (w_new_trace_flat[i*T_WIDTH +: T_WIDTH])
            );
        end
    endgenerate

    // ============================================================
    // 5. 輸出給 Layer 5
    // ============================================================
    // SRAM 讀出的資料已經是穩定且可靠的，直接輸出即可
    // 在 Phase 2 時，addr_in 穩定 4 拍，w_old_trace_flat 也會穩定供 STDP 取用
    assign trace_out_flat = w_old_trace_flat;

endmodule
`timescale 1ns/1ps

module lif_layer1_top #(
    parameter D_WIDTH    = 8,   // 電壓位寬
    parameter REF_WIDTH  = 4,   // 不應期計數器位寬
    parameter THRESHOLD  = 200, // 發火閾值
    parameter LEAK_SHIFT = 3,   // 漏電移位
    parameter REF_PERIOD = 3,   // 不應期長度
    parameter BATCH_NUM  = 98   // 784 pixels / 8 parallel = 98 cycles
)(
    input  wire clk,
    input  wire rst_n,
    
    // --- 控制介面 ---
    input  wire start,          // 開始處理一張圖片的訊號 (Pulse)
    output reg  busy,           // High 代表正在運算中
    output reg  finish,         // High 代表剛處理完一張圖 (Pulse)
    
    // --- 數據輸入介面 ---
    // 外部輸入 8 個像素 (8 * 8 bits = 64 bits)
    input  wire [63:0] pixel_data_in,
    // 告訴外部 Testbench 現在我要第幾個 Batch 的像素 (0~97)
    output wire [6:0]  req_addr, 
    
    // --- 數據輸出介面 ---
    // 輸出 8 個 Spikes 給 Layer 2 Buffer
    output wire [7:0]  spike_data_out,
    output reg         spike_valid
);

    // =======================================================
    // SRAM 定義：存放 784 個神經元的狀態
    // 每個地址存 8 顆神經元的狀態包：8 * (4 + 8) = 96 bits
    // =======================================================
    reg [95:0] state_sram [0:BATCH_NUM-1];

    reg  [6:0]  cur_batch_cnt;
    wire [95:0] sram_rdata;
    reg  [95:0] sram_wdata;
    
    // SRAM 讀取 (模擬 Distributed RAM，讀取無延遲)
    assign sram_rdata = state_sram[cur_batch_cnt];

    // 內部 Spike 匯流排
    wire [7:0] spikes_internal;
    
    // =======================================================
    // 8 核心並行實例化 (Parallel Instantiation)
    // =======================================================
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lif_gen
            
            // 訊號宣告
            wire [D_WIDTH-1:0]   v_old, v_new, pixel_in;
            wire [REF_WIDTH-1:0] ref_old, ref_new;

            // Unpacking: 從 96-bit 讀出第 i 個神經元的狀態
            // 格式: {Ref_Cnt(4), V_mem(8)}
            assign v_old    = sram_rdata[(i*12) +: D_WIDTH];
            assign ref_old  = sram_rdata[(i*12)+8 +: REF_WIDTH];
            
            // Unpacking: 從 64-bit 輸入讀出第 i 個像素
            assign pixel_in = pixel_data_in[(i*8) +: D_WIDTH];

            // 核心單元實例化
            lif_unit_core #(
                .D_WIDTH(D_WIDTH),
                .REF_WIDTH(REF_WIDTH),
                .THRESHOLD(THRESHOLD),
                .LEAK_SHIFT(LEAK_SHIFT),
                .REF_PERIOD(REF_PERIOD)
            ) u_core (
                .v_mem_old   (v_old),
                .ref_cnt_old (ref_old),
                .i_syn       (pixel_in),
                .v_mem_new   (v_new),
                .ref_cnt_new (ref_new),
                .spike_out   (spikes_internal[i])
            );

            // Packing: 準備寫回 SRAM 的數據
            always @(*) begin
                sram_wdata[(i*12) +: D_WIDTH]     = v_new;
                sram_wdata[(i*12)+8 +: REF_WIDTH] = ref_new;
            end
        end
    endgenerate

    // =======================================================
    // 控制狀態機 (FSM)
    // =======================================================
    localparam S_IDLE = 2'b00;
    localparam S_RUN  = 2'b01;
    
    reg [1:0] state, next_state;

    assign req_addr       = cur_batch_cnt;
    assign spike_data_out = spikes_internal;

    // State Transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: if (start) next_state = S_RUN;
            S_RUN:  if (cur_batch_cnt == BATCH_NUM - 1) next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    // Output Logic & Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_batch_cnt <= 0;
            busy          <= 0;
            finish        <= 0;
            spike_valid   <= 0;
            // 注意：這裡沒有自動清空 SRAM，若需重置狀態，建議在系統啟動時寫入 0
        end else begin
            finish      <= 0;
            spike_valid <= 0;
            sram_wdata  <= 96'd0; // 預設防止鎖存 (雖有 always @* 覆蓋)
            
            case (state)
                S_IDLE: begin
                    busy          <= 0;
                    cur_batch_cnt <= 0;
                    if (start) busy <= 1;
                end
                
                S_RUN: begin
                    busy        <= 1;
                    spike_valid <= 1; // 當前計算結果有效，Layer 2 Buffer 可寫入
                    
                    // 關鍵：將 8 顆核心運算好的新狀態寫回 SRAM
                    state_sram[cur_batch_cnt] <= sram_wdata;
                    
                    if (cur_batch_cnt == BATCH_NUM - 1) begin
                        finish        <= 1;
                        cur_batch_cnt <= 0;
                    end else begin
                        cur_batch_cnt <= cur_batch_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule
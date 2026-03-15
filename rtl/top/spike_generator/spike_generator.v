`timescale 1ns/1ps

module spike_generator #(
    parameter D_WIDTH    = 8,   
    parameter REF_WIDTH  = 4,   
    parameter THRESHOLD  = 200, 
    parameter LEAK_SHIFT = 3,   
    parameter REF_PERIOD = 3,   
    parameter BATCH_NUM  = 98   
)(
    input  wire clk,
    input  wire rst_n,
    
    // --- 控制介面 ---
    input  wire start,          
    input  wire accumulate_en,
    input  wire        pixel_valid_in, 
    output reg  busy,           
    output reg  finish,         
    
    // --- 數據輸入介面 ---
    input  wire [63:0] pixel_data_in,
    output reg  [6:0]  cur_batch_cnt,
    
    // --- 數據輸出介面 ---
    output wire [7:0]  spike_data_out,
    output wire        spike_valid 
);

    // =======================================================
    // 內部暫存器與組合邏輯信號
    // =======================================================
    reg  [6:0]  req_addr;      
    wire [95:0] sram_wdata_comb;    
    wire [7:0]  spikes_internal;

    // =======================================================
    // 實例化 Foundry RF IP (98x96, 無 Write Mask 版)
    // =======================================================
    wire [95:0] sram_q;             
    wire        sram_cen;           // Chip Enable (Active Low)
    wire        sram_wen;           // 單一 bit Write Enable (Active Low)
    wire [95:0] sram_d;             


    // 控制邏輯：

    // =======================================================
    // FSM 與狀態機邏輯
    // =======================================================
    localparam S_IDLE     = 3'd0;
    localparam S_CLEAR    = 3'd1;
    localparam S_PREFETCH = 3'd2;
    localparam S_RUN      = 3'd3;

    reg [2:0] state, next_state;
        // 控制邏輯：
    // - S_IDLE 時關閉 SRAM (cen = 1) 節省功耗。
    // - S_CLEAR 時寫入全 0 (wen = 0)。
    // - S_RUN 且 pixel_valid_in 時寫入計算結果 (wen = 0)。
    // - 其餘時間維持讀取狀態 (wen = 1)。
    assign sram_cen = (state == 3'd0 /* S_IDLE */) ? 1'b1 : 1'b0;
    assign sram_wen = ((state == 3'd1 /* S_CLEAR */) || (state == 3'd3 /* S_RUN */ && pixel_valid_in)) ? 1'b0 : 1'b1;
    assign sram_d   = (state == 3'd1 /* S_CLEAR */) ? 96'd0 : sram_wdata_comb;

    // --- 防 Hold-Time 假警報的線延遲 (1ns) ---
    wire [6:0]  sram_addr_dly;
    wire        sram_cen_dly;
    wire        sram_wen_dly;       
    wire [95:0] sram_d_dly;

    assign #1 sram_addr_dly = cur_batch_cnt;
    assign #1 sram_cen_dly  = sram_cen;
    assign #1 sram_wen_dly  = sram_wen;
    assign #1 sram_d_dly    = sram_d;

    // --- 實例化你專屬的 spike_gen_mem ---
    spike_gen_mem u_state_sram (
        .Q   (sram_q),
        .CLK (clk),
        .CEN (sram_cen_dly),
        .WEN (sram_wen_dly),
        .A   (sram_addr_dly),
        .D   (sram_d_dly),
        .EMA (3'b000)  // 💡 如果你生成的 RF 沒有 EMA 這個腳位，請直接把這行註解掉
    );
    
    // =======================================================
    // 8 核心並行實例化
    // =======================================================
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lif_gen
            wire [D_WIDTH-1:0]   v_old, v_new, pixel_in;
            wire [REF_WIDTH-1:0] ref_old, ref_new;

            // 讀取端直接接 SRAM 的 Q port
            assign v_old   = sram_q[(i*12) +: D_WIDTH];
            assign ref_old = sram_q[(i*12)+8 +: REF_WIDTH];
            assign pixel_in = pixel_data_in[(i*8) +: D_WIDTH];

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

            assign sram_wdata_comb[(i*12) +: D_WIDTH]     = v_new;
            assign sram_wdata_comb[(i*12)+8 +: REF_WIDTH] = ref_new;
        end
    endgenerate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (start) begin
                    if (accumulate_en) next_state = S_PREFETCH;
                    else               next_state = S_CLEAR;
                end
            end
            S_CLEAR: begin
                if (cur_batch_cnt == BATCH_NUM - 1) next_state = S_IDLE;
            end
            S_PREFETCH: begin
                next_state = S_RUN;
            end
            S_RUN: begin
                if (pixel_valid_in && cur_batch_cnt == BATCH_NUM - 1) next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    assign spike_valid = (state == S_RUN) && pixel_valid_in;
    assign spike_data_out = spikes_internal & {8{spike_valid}};

    // =======================================================
    // Output Logic
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_batch_cnt <= 0;
            busy          <= 0;
            finish        <= 0;
            req_addr      <= 0;
        end else begin
            finish      <= 0;

            case (state)
                S_IDLE: begin
                    busy          <= 0;
                    cur_batch_cnt <= 0;
                    if (start) busy <= 1;
                end

                S_CLEAR: begin
                    busy <= 1;
                    if (cur_batch_cnt == BATCH_NUM - 1) begin
                        cur_batch_cnt <= 0;
                        req_addr      <= 0;
                        finish        <= 0;
                    end else begin
                        cur_batch_cnt <= cur_batch_cnt + 1;
                    end
                end

                S_PREFETCH: begin
                    busy <= 1;
                    req_addr      <= 1; 
                    cur_batch_cnt <= 0;
                end

                S_RUN: begin
                    busy <= 1;
                    if (pixel_valid_in) begin 
                        if (cur_batch_cnt == BATCH_NUM - 1) begin
                            finish        <= 1;
                            cur_batch_cnt <= 0;
                            req_addr      <= 0;
                        end else begin
                            cur_batch_cnt <= cur_batch_cnt + 1;
                            if (req_addr < BATCH_NUM )
                                req_addr <= req_addr + 1;
                            else
                                req_addr <= 0;
                        end
                    end
                end
            endcase
        end
    end


endmodule

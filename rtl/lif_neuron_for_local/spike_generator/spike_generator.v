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
    output reg  busy,           
    output reg  finish,         
    
    // --- 數據輸入介面 ---
    input  wire [63:0] pixel_data_in,
    output reg  [6:0]  req_addr, 
    
    // --- 數據輸出介面 ---
    output wire [7:0]  spike_data_out,
    output wire        spike_valid // <--- [修正1] 改為 wire
);

    // =======================================================
    // SRAM 定義
    // =======================================================
    reg  [95:0] state_sram [0:BATCH_NUM-1];
    reg  [6:0]  cur_batch_cnt;      
    wire [95:0] sram_rdata;         
    wire [95:0] sram_wdata_comb;    

    assign sram_rdata = state_sram[cur_batch_cnt];

    wire [7:0] spikes_internal;
    
    // =======================================================
    // 8 核心並行實例化
    // =======================================================
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lif_gen
            wire [D_WIDTH-1:0]   v_old, v_new, pixel_in;
            wire [REF_WIDTH-1:0] ref_old, ref_new;

            assign v_old   = sram_rdata[(i*12) +: D_WIDTH];
            assign ref_old = sram_rdata[(i*12)+8 +: REF_WIDTH];
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

    assign spike_data_out = spikes_internal;

    // =======================================================
    // FSM
    // =======================================================
    localparam S_IDLE     = 3'd0;
    localparam S_CLEAR    = 3'd1;
    localparam S_PREFETCH = 3'd2;
    localparam S_RUN      = 3'd3;
    
    reg [2:0] state, next_state;

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
                if (cur_batch_cnt == BATCH_NUM - 1) next_state = S_PREFETCH;
            end
            S_PREFETCH: begin
                next_state = S_RUN;
            end
            S_RUN: begin
                if (cur_batch_cnt == BATCH_NUM - 1) next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // [修正2] 這行原本是對的，現在配合 output wire 使用
    assign spike_valid = (state == S_RUN);

    // =======================================================
    // Output Logic
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_batch_cnt <= 0;
            busy          <= 0;
            finish        <= 0;
            // spike_valid <= 0; // [修正3] 刪除這裡
            req_addr      <= 0;
        end else begin
            finish      <= 0;
            // spike_valid <= 0; // [修正3] 刪除這裡

            case (state)
                S_IDLE: begin
                    busy          <= 0;
                    cur_batch_cnt <= 0;
                    if (start) busy <= 1;
                end

                S_CLEAR: begin
                    busy <= 1;
                    state_sram[cur_batch_cnt] <= 96'd0; 
                    
                    if (cur_batch_cnt == BATCH_NUM - 1) begin
                        cur_batch_cnt <= 0;
                        req_addr      <= 0;
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
                    // spike_valid <= 1; // [修正3] 刪除這裡
                    
                    // 寫回計算結果
                    state_sram[cur_batch_cnt] <= sram_wdata_comb;

                    if (cur_batch_cnt == BATCH_NUM - 1) begin
                        finish        <= 1;
                        cur_batch_cnt <= 0;
                        req_addr      <= 0;
                    end else begin
                        cur_batch_cnt <= cur_batch_cnt + 1;
                        if (req_addr < BATCH_NUM - 1)
                            req_addr <= req_addr + 1;
                        else
                            req_addr <= 0;
                    end
                end
            endcase
        end
    end

endmodule
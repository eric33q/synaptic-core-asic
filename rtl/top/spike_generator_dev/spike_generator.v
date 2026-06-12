`timescale 1ns/1ps

module spike_generator #(
    parameter D_WIDTH    = 8,   
    parameter REF_WIDTH  = 4,   
    parameter THRESHOLD  = 200, 
    parameter LEAK_SHIFT = 3,   
    parameter REF_PERIOD = 3,   
    parameter BATCH_NUM  = 7'd98   
)(
    input  wire clk,
    input  wire rst_n,
    input  wire test_mode,
    input  wire start,          
    input  wire accumulate_en,
    input  wire pixel_valid_in, 
    output reg  busy,           
    output reg  finish,         
    input  wire [63:0] pixel_data_in,
    output reg  [6:0]  cur_batch_cnt,
    output wire [7:0]  spike_data_out,
    output wire        spike_valid 
);
    reg sram_finish;
    wire [95:0] sram_wdata_comb;    
    wire [7:0]  spikes_internal;
    wire        sram_cen;
    wire        sram_wen;
    wire [95:0] sram_d;             
    wire [95:0] sram_q_actual;
    reg  [95:0] test_bypass_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_bypass_reg <= 96'd0;
        end else if (test_mode) begin
            test_bypass_reg <= sram_d; 
        end
    end

    wire [95:0] sram_q = test_mode ? test_bypass_reg : sram_q_actual;
    localparam S_IDLE     = 3'd0;
    localparam S_CLEAR    = 3'd1;
    localparam S_PREFETCH = 3'd2;
    localparam S_RUN      = 3'd3;
    reg [2:0] state, next_state;
    assign sram_cen = (state == 3'd0) ? 1'b1 : 1'b0;
    assign sram_wen = ((state == 3'd1) || (state == 3'd3 && pixel_valid_in)) ? 1'b0 : 1'b1;
    assign sram_d   = (state == 3'd1) ? 96'd0 : sram_wdata_comb;
    spike_gen_mem u_state_sram (
        .Q   (sram_q_actual),
        .CLK (clk),
        .CEN (sram_cen),
        .WEN (sram_wen),
        .A   (cur_batch_cnt),
        .D   (sram_d),
        .EMA (3'b000)
    );
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lif_gen
            wire [D_WIDTH-1:0]   v_old, v_new, pixel_in;
            wire [REF_WIDTH-1:0] ref_old, ref_new;

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
                if (cur_batch_cnt == BATCH_NUM - 7'd1) next_state = S_IDLE;
            end
            S_PREFETCH: begin
                next_state = S_RUN;
            end
            S_RUN: begin
                if (pixel_valid_in && cur_batch_cnt == BATCH_NUM - 7'd1) next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    assign spike_valid = (state == S_RUN) && pixel_valid_in;
    assign spike_data_out = spikes_internal & {8{spike_valid}};
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_batch_cnt <= 7'd0;
            busy          <= 1'b0;
            finish        <= 1'b0;
            sram_finish   <= 1'b0;
        end else begin
            sram_finish <= 1'b0;
            finish      <= 1'b0;
            case (state)
                S_IDLE: begin
                    busy          <= 1'b0;
                    cur_batch_cnt <= 7'd0;
                    if (start) busy <= 1'b1;
                end
                S_CLEAR: begin
                    busy <= 1'b1;
                    if (cur_batch_cnt == BATCH_NUM - 7'd1) begin
                        cur_batch_cnt <= 7'd0;
                        sram_finish   <= 1'b1;
                    end else begin
                        cur_batch_cnt <= cur_batch_cnt + 7'd1;
                    end
                end
                S_PREFETCH: begin
                    busy <= 1'b1;
                    cur_batch_cnt <= 7'd0;
                end
                S_RUN: begin
                    busy <= 1'b1;
                    if (pixel_valid_in) begin 
                        if (cur_batch_cnt == BATCH_NUM - 7'd1) begin
                            finish        <= 1'b1;
                            cur_batch_cnt <= 7'd0;
                        end else begin
                            cur_batch_cnt <= cur_batch_cnt + 7'd1;
                        end
                    end
                end
            endcase
        end
    end
endmodule

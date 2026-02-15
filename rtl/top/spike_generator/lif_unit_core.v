`timescale 1ns/1ps

module lif_unit_core #(
    parameter D_WIDTH    = 8,
    parameter REF_WIDTH  = 4,
    parameter THRESHOLD  = 200,
    parameter LEAK_SHIFT = 3,
    parameter REF_PERIOD = 3
)(
    // 1. 來自 SRAM 的舊狀態 (Input)
    input  wire [D_WIDTH-1:0]   v_mem_old,
    input  wire [REF_WIDTH-1:0] ref_cnt_old,
    
    // 2. 來自圖片的輸入 (Input)
    input  wire [D_WIDTH-1:0]   i_syn,
    
    // 3. 計算結果 (Output - 準備寫回 SRAM)
    output reg  [D_WIDTH-1:0]   v_mem_new,
    output wire [REF_WIDTH-1:0] ref_cnt_new,
    
    // 4. 輸出脈衝 (Output - 給下一層)
    output wire                 spike_out
);

    // --- 內部連線 ---
    wire ref_active;
    wire [D_WIDTH-1:0] v_leaked;
    wire [D_WIDTH-1:0] v_integrated;
    wire spike_detected;

    assign spike_out = spike_detected & (~ref_active);

    // A. 不應期邏輯與計數更新
    layer1_lif_refrac_logic #( .REF_WIDTH(REF_WIDTH), .REF_PERIOD(REF_PERIOD) ) 
    u_refrac (
        .cnt_old    (ref_cnt_old),
        .post_spike (spike_out), // 迴授：看「當下」是否發火
        .cnt_new    (ref_cnt_new),
        .ref_active (ref_active)
    );

    // B. 漏電計算
    layer1_lif_leak #( .D_WIDTH(D_WIDTH), .LEAK_SHIFT(LEAK_SHIFT) ) 
    u_leak (
        .V_in   (v_mem_old),
        .V_leak (v_leaked)
    );

    // C. 積分計算 (加入輸入電流)
    layer1_lif_integrator #( .D_WIDTH(D_WIDTH) ) 
    u_int (
        .V_leak (v_leaked),
        .i_syn  (i_syn),
        .V_next (v_integrated)
    );

    // D. 閾值判斷 (注意：判斷的是積分後的 v_integrated)
    layer1_lif_th_cmp #( .D_WIDTH(D_WIDTH), .THRESHOLD(THRESHOLD) ) 
    u_cmp (
        .V_mem (v_integrated),
        .spike (spike_detected)
    );

    // E. 輸出邏輯與狀態重置 (MUX)
    // 如果在不應期，強制不發火

    always @(*) begin
        if (ref_active) begin
            // 情況 1: 不應期中 -> 電位歸零 (Resting Potential)
            v_mem_new = {D_WIDTH{1'b0}};
        end
        else if (spike_detected) begin
            // 情況 2: 發火後 -> Hard Reset (電位歸零)
            v_mem_new = {D_WIDTH{1'b0}};
        end
        else begin
            // 情況 3: 正常狀態 -> 更新積分後的電位
            v_mem_new = v_integrated;
        end
    end

endmodule
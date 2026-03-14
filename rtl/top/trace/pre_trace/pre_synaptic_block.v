`timescale 1ns/1ps

module pre_synaptic_block #(
    parameter D_WIDTH    = 8,   // 脈衝位寬 (8 pixels)
    parameter BATCH_NUM  = 98,  // 批次數量
    parameter T_WIDTH    = 8,   // Trace 位寬 (8 bits)
    parameter ADDR_WIDTH = 7    // log2(98) = 7
)(
    input  wire clk,
    input  wire rst_n,
    
    // --- 系統控制 ---
    input  wire start,
    input  wire accumulate_en,
    
    // --- 外部記憶體介面 (讀取圖片) ---
    input  wire [63:0] pixel_data_in, // 從 Image ROM 讀回的數據
    input wire pixel_valid_in, // 新增

    // 新增：供階段二讀取 Trace 的控制
    input  wire [6:0]  ext_addr,
    input  wire        is_update_phase,

    output wire [6:0]  cur_batch_cnt,      // 請求地址 (給 Image ROM，也給 Trace RAM)
    
    // --- 系統狀態 ---
    output wire L1_busy,
    output wire L1_done,

    // --- 給 Layer 5 (STDP) 與 Layer 2 (Neuron) 的核心輸出 ---
    // 1. 原始脈衝 (給 Layer 2 積分用，也給 Layer 5 判斷)
    output wire [D_WIDTH-1:0]               spike_data_out, 
    output wire                             spike_valid_out,
    
    // 2. 軌跡數值 (給 Layer 5 更新權重用)
    // 寬度 = 8個像素 * 8bit = 64 bits
    output wire [D_WIDTH*T_WIDTH-1:0]       trace_data_out
);

    // ============================================================
    // 內部連接線 (Internal Wires)
    // ============================================================
    // 這些線負責把 Layer 1 的輸出接進 Trace 的輸入
    wire [D_WIDTH-1:0]  w_spike_data;
    wire                w_spike_valid;
    wire [6:0]          w_req_addr;

    // ============================================================
    // 1. 實例化 Layer 1 (脈衝產生器頂層)
    // ============================================================
    layer1_system_top #(
        .D_WIDTH   (D_WIDTH),
        .BATCH_NUM (BATCH_NUM)
    ) u_layer1_top (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .accumulate_en  (accumulate_en),
        .pixel_valid_in (pixel_valid_in),
        // 外部記憶體 IO
        .pixel_data_in  (pixel_data_in),
        .cur_batch_cnt      (w_req_addr),    // 輸出地址，存到 wire
        
        // 狀態
        .L1_busy        (L1_busy),
        .L1_done        (L1_done),
        
        // 核心輸出 -> 接到內部 wire
        .L2_spike_data  (w_spike_data),
        .L2_valid       (w_spike_valid)
    );

    //根據不同階段切換地址來源，並在第二階段保護不被寫入
    wire [6:0] trace_addr = ext_addr;    
    // ============================================================
    // 2. 實例化 Pre_Trace (軌跡管理器)
    // ============================================================
    pre_trace #(
        .T_WIDTH    (T_WIDTH),
        .BATCH_NUM  (BATCH_NUM),
        .N_PARALLEL (D_WIDTH),   // 這裡對應 Layer 1 的輸出寬度 (8)
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_trace_manager (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // 控制訊號來自 Layer 1
        // 階段二不准更新，純讀取
        .update_en      (w_spike_valid && !is_update_phase),
        .addr_in        (trace_addr),    // Trace 的地址跟隨 L1 的讀取地址
        .spikes_in      (w_spike_data),  // 輸入脈衝
        
        // 輸出計算好的 Trace
        .trace_out_flat (trace_data_out)
    );

    // ============================================================
    // 3. 輸出指派
    // ============================================================
    // 將內部訊號拉到頂層輸出，方便後端模組使用
    assign cur_batch_cnt        = w_req_addr;
    assign spike_data_out  = w_spike_data;
    assign spike_valid_out = w_spike_valid;

endmodule
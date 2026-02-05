module pre_trace #(
    parameter T_WIDTH     = 8,      
    parameter DECAY_SHIFT = 2,      
    parameter INPUT_NUM   = 784,    // 總輸入數 (28x28)
    parameter BATCH_SIZE  = 8       // Layer 1 每次吐出的數量
)(
    input  wire                     clk,
    input  wire                     rst_n,
    // 直接對接 lif_layer1_top
    input  wire                     cmd_start,       // 對應 start (用來清空 buffer)
    input  wire                     cmd_finish,      // 對應 finish (用來觸發 Trace 更新)
    input  wire [BATCH_SIZE-1:0]    serial_spike_in, // 對應 spike_data_out
    input  wire [6:0]               batch_addr,      // 對應 req_addr
    input  wire                     spike_valid,     // 對應 spike_valid    
    // 輸出介面
    output wire [INPUT_NUM*T_WIDTH-1:0] STDP_trace_out
);
    // 784-bit 緩衝區 (SIPO Buffer)
    reg [INPUT_NUM-1:0] spike_buffer;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_buffer <= {INPUT_NUM{1'b0}};
        end else if (cmd_start) begin
            // 新的一張圖開始，先清空暫存
            spike_buffer <= {INPUT_NUM{1'b0}};
        end else if (spike_valid) begin
            // 收到數據，填入對應的位置
            spike_buffer[(batch_addr * BATCH_SIZE) +: BATCH_SIZE] <= serial_spike_in;
        end
    end

    // 只有當整張圖處理完 (cmd_finish=1) 的那個瞬間，所有 Core 一起更新
    genvar i;
    generate
        for (i = 0; i < INPUT_NUM; i = i + 1) begin : GEN_TRACE_ARRAY
            
            trace_core #(
                .T_WIDTH(T_WIDTH),
                .DECAY_SHIFT(DECAY_SHIFT)
            ) u_core (
                .clk(clk),
                .rst_n(rst_n),
                .update_en(cmd_finish),    
                .spike_in(spike_buffer[i]), 
                .trace_out(STDP_trace_out[ (i+1)*T_WIDTH-1 : i*T_WIDTH ])
            );
        end
    endgenerate

endmodule
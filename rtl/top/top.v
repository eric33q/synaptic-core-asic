module top #(
    parameter D_WIDTH      = 8,
    parameter BATCH_NUM    = 98,
    parameter ADDR_WIDTH   = 7,
    parameter I_WIDTH      = 18,
    parameter V_WIDTH      = 19,
    parameter THRESHOLD    = 800,
    parameter LEAK_SHIFT   = 3,
    parameter REF_PERIOD   = 3,
    parameter T_WIDTH      = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_loading,
    input  wire [6:0]  addr_in,     // SRAM 位址輸入
    input  wire [15:0] data_in,     // 16-bit 多工輸入 (權重/像素 共用)
    output wire        spike_out,
    output wire        busy,
    output wire        finish
);

    reg [1:0]  current_mode;
    reg [6:0]  load_counter; 
    reg [1:0]  data_cnt;     
    reg [63:0] pixel_data_in;
    reg        is_initialized; 

    reg        start;
    reg        accumulate_en;
    reg        pixel_valid_in; // 通知 Spike Gen 資料已備妥

    wire [63:0] rd_weight;      
    wire [6:0]  req_addr;         
    wire        rd_valid;     
    
    wire [7:0]  spike_data_out;         
    wire        spike_valid_out;         
    wire [D_WIDTH*T_WIDTH-1:0] trace_data_out; 
    
    wire [63:0] post_trace_8x;    
    
    wire [63:0] weight_new;  
    wire [7:0]  write_en;       
    
    wire        wr_en;
    wire [7:0]  wr_mask;
    wire [63:0] wr_weight;
    wire [6:0]  wr_row;

    reg [6:0] addr_pipe_n1; 
    reg [6:0] addr_pipe_n2;

    localparam ST_IDLE   = 2'b00; 
    localparam ST_LOAD   = 2'b01; 
    localparam ST_WORK   = 2'b10; 
    localparam ST_FINISH = 2'b11; 

    // =======================================================
    // FSM 與 核心控制邏輯
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode   <= ST_IDLE;
            load_counter   <= 7'd0;
            is_initialized <= 1'b0;
            start          <= 1'b0;
            accumulate_en  <= 1'b0;
        end else begin
            start <= 1'b0;

            case (current_mode)
                ST_IDLE: begin
                    if (start_loading) begin
                        if (!is_initialized) begin
                            current_mode <= ST_LOAD;
                            start <= 1'b1;
                            accumulate_en <= 1'b0;
                        end else begin
                            current_mode <= ST_WORK;
                            start <= 1'b1;
                            accumulate_en <= 1'b1;
                        end
                    end
                end

                ST_LOAD: begin
                    if (data_cnt == 2'd3) begin
                        if (load_counter == BATCH_NUM - 1) begin
                            current_mode   <= ST_IDLE; 
                            is_initialized <= 1'b1;
                            load_counter   <= 7'd0;
                        end else begin
                            load_counter <= load_counter + 1'b1;
                        end
                    end
                end

                ST_WORK: begin
                    if (finish) current_mode <= ST_FINISH;
                end

                ST_FINISH: begin
                    current_mode <= ST_IDLE;
                end

                default: current_mode <= ST_IDLE;
            endcase
        end
    end

    // =======================================================
    // Data Assembly & Pixel Valid Generator
    // =======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data_in  <= 64'd0;
            data_cnt       <= 2'd0;
            pixel_valid_in <= 1'b0;
        end else if (current_mode == ST_LOAD || current_mode == ST_WORK) begin
            pixel_data_in <= {data_in[15:0], pixel_data_in[63:16]};
            data_cnt <= data_cnt + 1'b1;
            
            // 每 4 拍湊滿一次，發出 1 拍的 Valid 給 Spike Gen
            if (current_mode == ST_WORK && data_cnt == 2'd3)
                pixel_valid_in <= 1'b1;
            else
                pixel_valid_in <= 1'b0;
                
        end else begin
            data_cnt <= 2'd0;
            pixel_valid_in <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_pipe_n1 <= 7'd0;
            addr_pipe_n2 <= 7'd0;
        end else begin
            addr_pipe_n1 <= req_addr;  
            addr_pipe_n2 <= addr_pipe_n1; 
        end
    end

    // =======================================================
    // 模組實例化
    // =======================================================
    pre_synaptic_block #(
        .D_WIDTH      (D_WIDTH),    
        .BATCH_NUM    (BATCH_NUM),  
        .T_WIDTH      (T_WIDTH),    
        .ADDR_WIDTH   (ADDR_WIDTH)  
    ) pre_synaptic_block (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (start),         
        .accumulate_en   (accumulate_en), 
        .pixel_valid_in  (pixel_valid_in),      
        .pixel_data_in   (pixel_data_in),   // 接回組裝好的 64-bit 暫存器
        .req_addr        (req_addr),    
        .L1_busy         (busy),              
        .L1_done         (finish),            
        .spike_data_out  (spike_data_out),    
        .spike_valid_out (spike_valid_out),    
        .trace_data_out  (trace_data_out)     
    );

    post_synaptic_block #(
        .V_WIDTH(V_WIDTH),    
        .T_WIDTH(T_WIDTH)    
    ) post_synaptic_block (
        .clk            (clk),
        .rst_n          (rst_n),
        .update_en      (finish),       
        .accum_en       (rd_valid),   
        .weight_mem_in  (rd_weight),
        .spike_out      (spike_out),    
        .post_trace_8x  (post_trace_8x)
    );

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stdp_group
            stdp #(
                .WEIGHT_WIDTH(D_WIDTH),
                .TRACE_WIDTH(T_WIDTH),
                .SHIFT_LTP(2),
                .SHIFT_LTD(3)
            ) stdp (
                .clk           (clk),
                .rst_n         (rst_n),
                .pre_spike_in  (spike_data_out[i]),
                .post_spike_in (spike_out),
                .weight_old    (rd_weight[i*D_WIDTH +: D_WIDTH]), 
                .pre_trace     (trace_data_out[i*T_WIDTH +: T_WIDTH]), 
                .post_trace    (post_trace_8x[i*T_WIDTH +: T_WIDTH]),
                .weight_new    (weight_new[i*D_WIDTH +: D_WIDTH]),
                .write_en      (write_en[i])
            );
        end
    endgenerate
    
    // =======================================================
    // Write Arbitration (權重記憶體寫入仲裁)
    // =======================================================
    // ST_WORK 期間只要有 STDP 寫入請求就放行，不再只等 finish
    assign wr_en = (current_mode == ST_LOAD) ? (data_cnt == 2'd3) : 
                   (current_mode == ST_WORK) ? (|write_en) : 1'b0;
                         
    assign wr_mask   = (current_mode == ST_LOAD) ? 8'hFF : write_en; 
    assign wr_weight = (current_mode == ST_LOAD) ? pixel_data_in : weight_new; 
    assign wr_row    = (current_mode == ST_LOAD) ? addr_in : addr_pipe_n2;
 
    // Weight Memory
    we_unit_98x64 we_unit_98x64 (
        .clk        (clk),
        .rst_n      (rst_n),
        .rd_en      (spike_valid_out),      
        .rd_row     (req_addr),      
        .pre_mask   (spike_data_out),           
        .rd_weight  (rd_weight),
        .rd_valid   (rd_valid),  
        .wr_en      (wr_en),     
        .wr_mask    (wr_mask), 
        .wr_row     (wr_row),   
        .wr_weight  (wr_weight)    
    );

endmodule


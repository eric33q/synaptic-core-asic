module we_unit_8x64(
    input  wire         clk,
    input  wire         rst_n,

    // Sync read (1-cycle latency)
    input  wire         rd_en,
    input  wire [2:0]   rd_addr,
    output reg  [63:0]  rd_data,
    output reg          rd_valid,

    // Sync write
    input  wire         wr_en,
    input  wire [2:0]   wr_addr,
    input  wire [63:0]  wr_data,

    // Byte write enable: wr_be[0] -> [7:0], wr_be[7] -> [63:56]
    input  wire [7:0]   wr_be
);
    // 8x64 bits memory array
    reg [63:0] sram_mem [0:7];

    // Write operation
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                sram_mem[i] <= 64'b0;
            end
        end
        else if (wr_en) begin
            for (i = 0; i < 8; i = i + 1) begin
                if (wr_be[i]) begin
                    sram_mem[wr_addr][i*8 +: 8] <= wr_data[i*8 +: 8];
                end
            end
        end
    end

    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data  <= 64'b0;
            rd_valid <= 1'b0;
        end
        else if (rd_en) begin
            rd_data  <= sram_mem[rd_addr];
            rd_valid <= 1'b1;
        end
        else begin
            rd_valid <= 1'b0;
        end
    end
endmodule
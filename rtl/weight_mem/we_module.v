module we_module(
    input  wire         clk,
    input  wire         rst_n,

    input  wire [63:0]  spike_in,

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
endmodule
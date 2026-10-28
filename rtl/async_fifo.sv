module async_fifo #(
    parameter integer DATA_WIDTH = 8,
    parameter integer ADDR_WIDTH = 4
)(
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,

    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,

    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  full,
    output wire                  empty
);

    localparam integer PTR_WIDTH = ADDR_WIDTH + 1;

    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr;

    wire [PTR_WIDTH-1:0] unused_wr_binary;
    wire [PTR_WIDTH-1:0] wr_gray;

    wire [PTR_WIDTH-1:0] unused_rd_binary;
    wire [PTR_WIDTH-1:0] rd_gray;

    wire [PTR_WIDTH-1:0] wr_gray_sync;
    wire [PTR_WIDTH-1:0] rd_gray_sync;

    wire write_valid;

    assign write_valid = wr_en && !full;

    // Write pointer and full detection
    async_fifo_write_ptr #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_write_ptr (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),
        .rd_gray_sync(rd_gray_sync),
        .wr_addr(wr_addr),
        .wr_binary(unused_wr_binary),
        .wr_gray(wr_gray),
        .full(full)
    );

    // Read pointer and empty detection
    async_fifo_read_ptr #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_read_ptr (
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),
        .wr_gray_sync(wr_gray_sync),
        .rd_addr(rd_addr),
        .rd_binary(unused_rd_binary),
        .rd_gray(rd_gray),
        .empty(empty)
    );

    // Synchronize read pointer into write clock domain
    cdc_sync #(
        .WIDTH(PTR_WIDTH)
    ) u_read_to_write_sync (
        .dst_clk(wr_clk),
        .dst_rst_n(wr_rst_n),
        .async_gray(rd_gray),
        .sync_gray(rd_gray_sync)
    );

    // Synchronize write pointer into read clock domain
    cdc_sync #(
        .WIDTH(PTR_WIDTH)
    ) u_write_to_read_sync (
        .dst_clk(rd_clk),
        .dst_rst_n(rd_rst_n),
        .async_gray(wr_gray),
        .sync_gray(wr_gray_sync)
    );

    // Dual-clock FIFO storage
    async_fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_memory (
        .wr_clk(wr_clk),
        .wr_en(write_valid),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule

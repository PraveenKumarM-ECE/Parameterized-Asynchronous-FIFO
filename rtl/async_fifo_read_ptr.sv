module async_fifo_read_ptr #(
    parameter integer ADDR_WIDTH = 4
)(
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,

    input  wire [ADDR_WIDTH:0]   wr_gray_sync,

    output wire [ADDR_WIDTH-1:0] rd_addr,
    output reg  [ADDR_WIDTH:0]   rd_binary,
    output reg  [ADDR_WIDTH:0]   rd_gray,
    output reg                   empty
);

    localparam integer PTR_WIDTH = ADDR_WIDTH + 1;

    wire read_valid;
    wire [PTR_WIDTH-1:0] binary_next;
    wire [PTR_WIDTH-1:0] gray_next;

    assign read_valid = rd_en && !empty;

    assign binary_next =
        rd_binary + {{(PTR_WIDTH-1){1'b0}}, read_valid};

    assign gray_next = binary_next ^ (binary_next >> 1);

    assign rd_addr = rd_binary[ADDR_WIDTH-1:0];

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_binary <= '0;
            rd_gray   <= '0;
            empty     <= 1'b1;
        end
        else begin
            rd_binary <= binary_next;
            rd_gray   <= gray_next;
            empty     <= (gray_next == wr_gray_sync);
        end
    end

endmodule

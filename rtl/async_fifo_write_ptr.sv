module async_fifo_write_ptr #(
    parameter integer ADDR_WIDTH = 4
)(
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,

    input  wire [ADDR_WIDTH:0]   rd_gray_sync,

    output wire [ADDR_WIDTH-1:0] wr_addr,
    output reg  [ADDR_WIDTH:0]   wr_binary,
    output reg  [ADDR_WIDTH:0]   wr_gray,
    output reg                   full
);

    localparam integer PTR_WIDTH = ADDR_WIDTH + 1;

    wire write_valid;
    wire [PTR_WIDTH-1:0] binary_next;
    wire [PTR_WIDTH-1:0] gray_next;
    wire [PTR_WIDTH-1:0] full_compare;

    assign write_valid = wr_en && !full;

    assign binary_next = wr_binary + {{(PTR_WIDTH-1){1'b0}}, write_valid};
    assign gray_next = binary_next ^ (binary_next >> 1);

    // Invert two MSBs of synchronized read pointer
    assign full_compare = {
        ~rd_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
         rd_gray_sync[ADDR_WIDTH-2:0]
    };

    assign wr_addr = wr_binary[ADDR_WIDTH-1:0];

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_binary <= '0;
            wr_gray   <= '0;
            full      <= 1'b0;
        end
        else begin
            wr_binary <= binary_next;
            wr_gray   <= gray_next;
            full      <= (gray_next == full_compare);
        end
    end

endmodule

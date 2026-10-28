module gray_pointer_counter #(
    parameter integer ADDR_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    output reg  [ADDR_WIDTH:0]   binary_ptr,
    output reg  [ADDR_WIDTH:0]   gray_ptr
);

    wire [ADDR_WIDTH:0] binary_next;
    wire [ADDR_WIDTH:0] gray_next;

    assign binary_next = binary_ptr +
                         {{ADDR_WIDTH{1'b0}}, enable};

    assign gray_next = (binary_next >> 1) ^ binary_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_ptr <= '0;
            gray_ptr   <= '0;
        end
        else begin
            binary_ptr <= binary_next;
            gray_ptr   <= gray_next;
        end
    end

endmodule

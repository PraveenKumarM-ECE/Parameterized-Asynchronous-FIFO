module gray_to_bin #(
    parameter integer WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    genvar i;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_GRAY_TO_BIN
            assign bin[i] = ^gray[WIDTH-1:i];
        end
    endgenerate

endmodule

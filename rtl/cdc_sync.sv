module cdc_sync #(
    parameter integer WIDTH = 5
)(
    input  wire             dst_clk,
    input  wire             dst_rst_n,
    input  wire [WIDTH-1:0] async_gray,
    output wire [WIDTH-1:0] sync_gray
);

    (* async_reg = "true" *)
    reg [WIDTH-1:0] sync_stage1;

    (* async_reg = "true" *)
    reg [WIDTH-1:0] sync_stage2;

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sync_stage1 <= '0;
            sync_stage2 <= '0;
        end
        else begin
            sync_stage1 <= async_gray;
            sync_stage2 <= sync_stage1;
        end
    end

    assign sync_gray = sync_stage2;

endmodule

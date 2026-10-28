`timescale 1ns/1ps

module tb_sync_fifo;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer DEPTH = (1 << AW);

    reg clk = 0;
    reg rst_n = 0;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [DW-1:0] wr_data = 0;

    wire [DW-1:0] rd_data;
    wire full, empty;
    wire [AW:0] count;

    integer passed = 0;
    integer failed = 0;
    integer i;

    sync_fifo #(
        .DATA_WIDTH(DW),
        .ADDR_WIDTH(AW)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty),
        .count(count)
    );

    always #5 clk = ~clk;

    task automatic check(
        input integer expected_count,
        input bit expected_full,
        input bit expected_empty
    );
        begin
            if (count === expected_count &&
                full === expected_full &&
                empty === expected_empty)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display("FAIL flags count=%0d full=%b empty=%b",
                         count, full, empty);
            end
        end
    endtask

    task automatic write_byte(input reg [DW-1:0] value);
        begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 0;
            wr_data = value;

            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task automatic read_byte(input reg [DW-1:0] expected);
        begin
            @(negedge clk);
            wr_en = 0;
            rd_en = 1;
            #1;

            if (rd_data === expected)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display("FAIL data expected=%h got=%h",
                         expected, rd_data);
            end

            @(negedge clk);
            rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/day2_sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        repeat (2) @(negedge clk);
        rst_n = 1;

        #1;
        check(0, 0, 1);

        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(i + 8'h40);

        #1;
        check(DEPTH, 1, 0);

        write_byte(8'hFF);
        #1;
        check(DEPTH, 1, 0);

        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(i + 8'h40);

        #1;
        check(0, 0, 1);

        @(negedge clk);
        rd_en = 1;
        @(negedge clk);
        rd_en = 0;

        #1;
        check(0, 0, 1);

        write_byte(8'hA5);
        read_byte(8'hA5);

        #1;
        check(0, 0, 1);

        $display("================================");
        $display("DAY 2: PASSED=%0d FAILED=%0d", passed, failed);
        $display("================================");

        if (failed != 0)
            $fatal(1, "DAY 2 FAILED");

        $display("DAY 2 TEST PASSED");
        $finish;
    end

endmodule

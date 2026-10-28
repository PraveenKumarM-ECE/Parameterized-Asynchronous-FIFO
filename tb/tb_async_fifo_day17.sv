`timescale 1ns/1ps

module tb_async_fifo_day17;

    parameter integer WR_HALF = 5;
    parameter integer RD_HALF = 10;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer TOTAL = 256;

    reg wr_clk = 0;
    reg rd_clk = 0;
    reg wr_rst_n = 0;
    reg rd_rst_n = 0;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [DW-1:0] wr_data = 0;

    wire [DW-1:0] rd_data;
    wire full;
    wire empty;

    reg [DW-1:0] scoreboard [0:TOTAL-1];

    integer writes = 0;
    integer reads = 0;
    integer passed = 0;
    integer failed = 0;
    integer full_hits = 0;
    integer empty_hits = 0;

    reg writer_done = 0;
    reg reader_done = 0;

    reg [DW-1:0] expected;

    async_fifo #(
        .DATA_WIDTH(DW),
        .ADDR_WIDTH(AW)
    ) dut (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    always #(WR_HALF) wr_clk = ~wr_clk;
    always #(RD_HALF) rd_clk = ~rd_clk;

    task automatic check(
        input reg condition,
        input string description
    );
        begin
            if (condition)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display("[FAIL] %s at %0t",
                         description, $time);
            end
        end
    endtask

    // Write-domain driver
    initial begin
        wait(wr_rst_n);

        @(negedge wr_clk);

        while (writes < TOTAL) begin
            if (!full) begin
                wr_en = 1;
                wr_data = DW'((writes * 13 + 7) % 256);

                scoreboard[writes] = wr_data;

                @(posedge wr_clk);
                #1;

                writes = writes + 1;

                @(negedge wr_clk);
                wr_en = 0;
            end else begin
                full_hits = full_hits + 1;
                @(negedge wr_clk);
            end
        end

        writer_done = 1;
    end

    // Read-domain checker
    initial begin
        wait(rd_rst_n);

        @(negedge rd_clk);

        while (reads < TOTAL) begin
            if (!empty) begin
                rd_en = 1;
                #1;

                expected = scoreboard[reads];

                check(
                    rd_data === expected,
                    "Data integrity"
                );

                @(posedge rd_clk);
                #1;

                reads = reads + 1;

                @(negedge rd_clk);
                rd_en = 0;
            end else begin
                empty_hits = empty_hits + 1;
                @(negedge rd_clk);
            end
        end

        reader_done = 1;
    end

    initial begin
        $dumpfile("sim/day17_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day17);

        $display("======================================");
        $display("DAY 17 - CLOCK RATIO VERIFICATION");
        $display("======================================");

        $display("WRITE HALF PERIOD = %0d ns", WR_HALF);
        $display("READ HALF PERIOD  = %0d ns", RD_HALF);

        repeat (5) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        wait(writer_done && reader_done);

        repeat (5) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "FIFO empty after transfers");

        check(full === 1'b0,
              "FIFO not full after transfers");

        check(writes == TOTAL,
              "All writes completed");

        check(reads == TOTAL,
              "All reads completed");

        $display("--------------------------------------");
        $display("WRITES        = %0d", writes);
        $display("READS         = %0d", reads);
        $display("FULL HITS     = %0d", full_hits);
        $display("EMPTY HITS    = %0d", empty_hits);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 17 FAILED");

        if (writes != TOTAL || reads != TOTAL)
            $fatal(1, "DAY 17 COVERAGE FAILED");

        $display("DAY 17 TEST PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "DAY 17 TIMEOUT");
    end

endmodule

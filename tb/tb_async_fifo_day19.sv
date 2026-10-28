`timescale 1ns/1ps

module tb_async_fifo_day19;

    parameter integer SEED = 12345;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer TOTAL = 1000;

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
    integer write_pauses = 0;
    integer read_pauses = 0;

    integer wr_rng;
    integer rd_rng;
    integer wr_random;
    integer rd_random;

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

    // Independent clocks
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    task automatic check(
        input reg condition,
        input string description
    );
        begin
            if (condition)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] %s at %0t",
                    description, $time
                );
            end
        end
    endtask

    // Randomized write driver
    initial begin
        wr_rng = SEED;
        wait(wr_rst_n);

        @(negedge wr_clk);

        while (writes < TOTAL) begin

            wr_random = $random(wr_rng);

            if (full)
                full_hits = full_hits + 1;

            if (!full && ((wr_random & 32'h7fffffff) % 100 < 75)) begin

                wr_en = 1;
                wr_data = DW'($random(wr_rng));

                scoreboard[writes] = wr_data;

                @(posedge wr_clk);
                #1;

                writes = writes + 1;

                @(negedge wr_clk);
                wr_en = 0;

            end else begin

                write_pauses = write_pauses + 1;
                @(negedge wr_clk);

            end
        end

        writer_done = 1;
    end

    // Randomized read checker
    initial begin
        rd_rng = SEED ^ 32'h5A5A5A5A;
        wait(rd_rst_n);

        @(negedge rd_clk);

        while (reads < TOTAL) begin

            rd_random = $random(rd_rng);

            if (empty)
                empty_hits = empty_hits + 1;

            if (!empty && ((rd_random & 32'h7fffffff) % 100 < 70)) begin

                rd_en = 1;
                #1;

                expected = scoreboard[reads];

                check(
                    rd_data === expected,
                    "Randomized scoreboard data"
                );

                @(posedge rd_clk);
                #1;

                reads = reads + 1;

                @(negedge rd_clk);
                rd_en = 0;

            end else begin

                read_pauses = read_pauses + 1;
                @(negedge rd_clk);

            end
        end

        reader_done = 1;
    end

    initial begin
        $dumpfile("sim/day19_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day19);

        $display("======================================");
        $display("DAY 19 - RANDOMIZED FIFO VERIFICATION");
        $display("======================================");

        $display("RANDOM SEED = %0d", SEED);

        repeat (5) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        wait(writer_done && reader_done);

        repeat (5) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "FIFO empty after randomized test");

        check(full === 1'b0,
              "FIFO not full after randomized test");

        check(writes == TOTAL,
              "All randomized writes completed");

        check(reads == TOTAL,
              "All randomized reads completed");

        check(write_pauses > 0,
              "Write backpressure exercised");

        check(read_pauses > 0,
              "Read backpressure exercised");

        $display("--------------------------------------");
        $display("WRITES        = %0d", writes);
        $display("READS         = %0d", reads);
        $display("FULL HITS     = %0d", full_hits);
        $display("EMPTY HITS    = %0d", empty_hits);
        $display("WRITE PAUSES  = %0d", write_pauses);
        $display("READ PAUSES   = %0d", read_pauses);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 19 FAILED");

        $display("DAY 19 TEST PASSED");
        $finish;
    end

    initial begin
        #500000;
        $fatal(1, "DAY 19 TIMEOUT");
    end

endmodule

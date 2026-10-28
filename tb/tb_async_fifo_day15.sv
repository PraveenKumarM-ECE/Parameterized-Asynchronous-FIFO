`timescale 1ns/1ps

module tb_async_fifo_day15;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer DEPTH = (1 << AW);
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

    integer write_index = 0;
    integer read_index = 0;
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
                    "[FAIL] %s at time %0t",
                    description, $time
                );
            end
        end
    endtask

    // Writer
    initial begin
        wait(wr_rst_n);

        @(negedge wr_clk);

        while (write_index < TOTAL) begin

            if (!full) begin
                wr_en = 1;
                wr_data = DW'((write_index * 7 + 3) % 256);

                scoreboard[write_index] = wr_data;

                @(posedge wr_clk);
                #1;

                write_index = write_index + 1;

                @(negedge wr_clk);
                wr_en = 0;
            end
            else begin
                full_hits = full_hits + 1;
                @(negedge wr_clk);
            end

        end

        writer_done = 1;
    end

    // Reader
    initial begin
        wait(rd_rst_n);

        @(negedge rd_clk);

        while (read_index < TOTAL) begin

            if (!empty) begin

                rd_en = 1;
                #1;

                expected = scoreboard[read_index];

                check(
                    rd_data === expected,
                    "Scoreboard data integrity"
                );

                @(posedge rd_clk);
                #1;

                read_index = read_index + 1;

                @(negedge rd_clk);
                rd_en = 0;
            end
            else begin
                empty_hits = empty_hits + 1;
                @(negedge rd_clk);
            end

        end

        reader_done = 1;
    end

    // Main test control
    initial begin
        $dumpfile("sim/day15_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day15);

        $display("======================================");
        $display("DAY 15 - ADVANCED FIFO VERIFICATION");
        $display("======================================");

        repeat (5) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        wait(writer_done && reader_done);

        repeat (5) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "FIFO empty after all reads");
        check(full === 1'b0, "FIFO not full after drain");

        check(write_index == TOTAL, "All writes completed");
        check(read_index == TOTAL, "All reads completed");

        $display("--------------------------------------");
        $display("TOTAL WRITES  = %0d", write_index);
        $display("TOTAL READS   = %0d", read_index);
        $display("FULL HITS     = %0d", full_hits);
        $display("EMPTY HITS    = %0d", empty_hits);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 15 FAILED");

        if (write_index != TOTAL || read_index != TOTAL)
            $fatal(1, "DAY 15 COVERAGE FAILED");

        $display("DAY 15 TEST PASSED");
        $finish;
    end

    // Timeout
    initial begin
        #200000;
        $fatal(1, "DAY 15 TIMEOUT");
    end

endmodule

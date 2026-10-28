`timescale 1ns/1ps

module tb_fifo_day6 #(
    parameter integer DW = 8,
    parameter integer AW = 4,
    parameter integer TEST_CYCLES = 500
);

    localparam integer DEPTH = (1 << AW);

    reg clk = 0;
    reg rst_n = 0;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [DW-1:0] wr_data = 0;

    wire [DW-1:0] rd_data;
    wire full;
    wire empty;
    wire [AW:0] count;

    reg [DW-1:0] scoreboard [0:DEPTH-1];

    integer head = 0;
    integer tail = 0;
    integer occupancy = 0;

    integer passed = 0;
    integer failed = 0;
    integer writes = 0;
    integer reads = 0;
    integer blocked_writes = 0;
    integer blocked_reads = 0;
    integer i;

    reg do_write;
    reg do_read;
    reg [DW-1:0] expected_data;

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

    task automatic check_flags;
        begin
            if ((count === (AW+1)'(occupancy)) &&
                (full === (occupancy == DEPTH)) &&
                (empty === (occupancy == 0)))
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] Cycle=%0d Count=%0d Expected=%0d Full=%b Empty=%b",
                    i, count, occupancy, full, empty
                );
            end
        end
    endtask

    task automatic check_pointers;
        begin
            if ((dut.wr_ptr === AW'(tail)) &&
                (dut.rd_ptr === AW'(head)))
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] Pointer mismatch cycle=%0d",
                    i
                );
            end
        end
    endtask

    initial begin
        $dumpfile("sim/day6_parameterized_fifo.vcd");
        $dumpvars(0, tb_fifo_day6);

        $display("========================================");
        $display("DAY 6 - PARAMETERIZED FIFO VERIFICATION");
        $display("DATA_WIDTH=%0d DEPTH=%0d", DW, DEPTH);
        $display("========================================");

        repeat (3) @(negedge clk);
        rst_n = 1;

        #1;
        check_flags();
        check_pointers();

        for (i = 0; i < TEST_CYCLES; i = i + 1) begin

            @(negedge clk);

            wr_en = ($urandom_range(0, 99) < 65);
            rd_en = ($urandom_range(0, 99) < 60);

            wr_data = DW'($urandom);

            do_read = rd_en && (occupancy > 0);

            do_write = wr_en &&
                       ((occupancy < DEPTH) || do_read);

            if (wr_en && !do_write)
                blocked_writes = blocked_writes + 1;

            if (rd_en && !do_read)
                blocked_reads = blocked_reads + 1;

            if (do_read) begin
                expected_data = scoreboard[head];

                #1;

                if (rd_data === expected_data)
                    passed = passed + 1;
                else begin
                    failed = failed + 1;
                    $display(
                        "[FAIL] DATA cycle=%0d expected=%h got=%h",
                        i, expected_data, rd_data
                    );
                end
            end

            @(posedge clk);
            #1;

            if (do_read) begin
                head = (head + 1) % DEPTH;
                reads = reads + 1;
            end

            if (do_write) begin
                scoreboard[tail] = wr_data;
                tail = (tail + 1) % DEPTH;
                writes = writes + 1;
            end

            occupancy = occupancy +
                        do_write - do_read;

            check_flags();
            check_pointers();
        end

        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        $display("----------------------------------------");
        $display("WRITES          = %0d", writes);
        $display("READS           = %0d", reads);
        $display("BLOCKED WRITES  = %0d", blocked_writes);
        $display("BLOCKED READS   = %0d", blocked_reads);
        $display("PASSED CHECKS   = %0d", passed);
        $display("FAILED CHECKS   = %0d", failed);
        $display("----------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 6 FAILED");

        $display(
            "DAY 6 TEST PASSED - WIDTH=%0d DEPTH=%0d",
            DW, DEPTH
        );

        $finish;
    end

endmodule

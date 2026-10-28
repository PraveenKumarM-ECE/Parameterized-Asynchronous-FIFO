`timescale 1ns/1ps

module tb_fifo_day4;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer DEPTH = (1 << AW);
    localparam integer TEST_CYCLES = 1000;

    reg clk = 0;
    reg rst_n = 0;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [DW-1:0] wr_data = 0;

    wire [DW-1:0] rd_data;
    wire full, empty;
    wire [AW:0] count;

    reg [DW-1:0] scoreboard [0:DEPTH-1];

    integer head = 0;
    integer tail = 0;
    integer expected_count = 0;

    integer passed = 0;
    integer failed = 0;
    integer writes = 0;
    integer reads = 0;
    integer blocked_writes = 0;
    integer blocked_reads = 0;
    integer simultaneous = 0;

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
            if (count === expected_count &&
                full === (expected_count == DEPTH) &&
                empty === (expected_count == 0))
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display("[FAIL] Cycle=%0d Count=%0d Expected=%0d",
                         i, count, expected_count);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/day4_random_fifo.vcd");
        $dumpvars(0, tb_fifo_day4);

        $display("====================================");
        $display("DAY 4 - RANDOMIZED FIFO VERIFICATION");
        $display("====================================");

        repeat (3) @(negedge clk);
        rst_n = 1;

        #1;
        check_flags();

        for (i = 0; i < TEST_CYCLES; i = i + 1) begin

            @(negedge clk);

            wr_en = ($urandom_range(0, 99) < 65);
            rd_en = ($urandom_range(0, 99) < 60);
            wr_data = $urandom;

            do_read = rd_en && (expected_count > 0);
            do_write = wr_en &&
                       ((expected_count < DEPTH) || do_read);

            if (wr_en && rd_en)
                simultaneous = simultaneous + 1;

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
                    $display("[FAIL] Data mismatch cycle=%0d expected=%h got=%h",
                             i, expected_data, rd_data);
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

            expected_count = expected_count +
                             do_write - do_read;

            check_flags();
        end

        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        $display("====================================");
        $display("TOTAL CYCLES      = %0d", TEST_CYCLES);
        $display("SUCCESSFUL WRITES = %0d", writes);
        $display("SUCCESSFUL READS  = %0d", reads);
        $display("BLOCKED WRITES    = %0d", blocked_writes);
        $display("BLOCKED READS     = %0d", blocked_reads);
        $display("SIMULTANEOUS OPS  = %0d", simultaneous);
        $display("PASSED CHECKS     = %0d", passed);
        $display("FAILED CHECKS     = %0d", failed);
        $display("====================================");

        if (failed != 0)
            $fatal(1, "DAY 4 FAILED");

        $display("DAY 4 TEST PASSED");
        $finish;
    end

endmodule

`timescale 1ns/1ps

module tb_fifo_day5;

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
    integer cycles = 0;
    integer i;

    reg [DW-1:0] model [0:DEPTH-1];

    integer head = 0;
    integer tail = 0;
    integer occupancy = 0;

    reg expected_read;
    reg expected_write;
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
            if (count === occupancy &&
                full === (occupancy == DEPTH) &&
                empty === (occupancy == 0))
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] Flags cycle=%0d count=%0d expected=%0d full=%b empty=%b",
                    cycles, count, occupancy, full, empty
                );
            end
        end
    endtask

    task automatic check_pointers;
        begin
            if (dut.wr_ptr === tail &&
                dut.rd_ptr === head)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] Pointers wr=%0d expected=%0d rd=%0d expected=%0d",
                    dut.wr_ptr, tail, dut.rd_ptr, head
                );
            end
        end
    endtask

    task automatic transaction(
        input reg write_req,
        input reg read_req,
        input reg [DW-1:0] value
    );
        begin
            @(negedge clk);

            wr_en = write_req;
            rd_en = read_req;
            wr_data = value;

            expected_read = read_req && (occupancy > 0);

            expected_write = write_req &&
                             ((occupancy < DEPTH) || expected_read);

            #1;

            if (expected_read) begin
                expected_data = model[head];

                if (rd_data === expected_data)
                    passed = passed + 1;
                else begin
                    failed = failed + 1;
                    $display(
                        "[FAIL] Data cycle=%0d expected=%h got=%h",
                        cycles, expected_data, rd_data
                    );
                end
            end

            @(posedge clk);
            #1;

            if (expected_read)
                head = (head + 1) % DEPTH;

            if (expected_write) begin
                model[tail] = value;
                tail = (tail + 1) % DEPTH;
            end

            occupancy = occupancy +
                        expected_write - expected_read;

            cycles = cycles + 1;

            check_flags();
            check_pointers();

            @(negedge clk);
            wr_en = 0;
            rd_en = 0;
        end
    endtask

    task automatic reset_fifo;
        begin
            @(negedge clk);

            rst_n = 0;
            wr_en = 0;
            rd_en = 0;

            head = 0;
            tail = 0;
            occupancy = 0;

            #1;
            check_flags();
            check_pointers();

            @(negedge clk);
            rst_n = 1;
        end
    endtask

    initial begin
        $dumpfile("sim/day5_fifo_flags.vcd");
        $dumpvars(0, tb_fifo_day5);

        $display("======================================");
        $display("DAY 5 - FIFO FLAG AND POINTER TEST");
        $display("======================================");

        // Test 1: Initial reset
        reset_fifo();

        // Test 2: Fill FIFO completely
        for (i = 0; i < DEPTH; i = i + 1)
            transaction(1, 0, i + 8'h10);

        // Test 3: Overflow protection
        transaction(1, 0, 8'hFF);

        // Test 4: Simultaneous read/write at full
        for (i = 0; i < DEPTH; i = i + 1)
            transaction(1, 1, i + 8'h80);

        // Test 5: Drain FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            transaction(0, 1, 0);

        // Test 6: Underflow protection
        transaction(0, 1, 0);

        // Test 7: Simultaneous request at empty
        transaction(1, 1, 8'hA5);
        transaction(0, 1, 0);

        // Test 8: Repeated pointer wraparound
        for (i = 0; i < 64; i = i + 1) begin
            transaction(1, 0, i[7:0]);
            transaction(0, 1, 0);
        end

        // Test 9: Reset with pending data
        for (i = 0; i < 8; i = i + 1)
            transaction(1, 0, i + 8'hC0);

        reset_fifo();

        // Test 10: Recovery after reset
        transaction(1, 0, 8'h5A);
        transaction(0, 1, 0);

        $display("======================================");
        $display("TOTAL TRANSACTIONS = %0d", cycles);
        $display("PASSED CHECKS      = %0d", passed);
        $display("FAILED CHECKS      = %0d", failed);
        $display("======================================");

        if (failed != 0)
            $fatal(1, "DAY 5 FAILED");

        $display("DAY 5 TEST PASSED");
        $finish;
    end

endmodule

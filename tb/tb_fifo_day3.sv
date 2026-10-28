`timescale 1ns/1ps

module tb_fifo_day3;

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

    reg [DW-1:0] expected_mem [0:DEPTH-1];
    integer head = 0;
    integer tail = 0;
    integer expected_count = 0;

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
                empty === (expected_count == 0)) begin
                passed = passed + 1;
            end
            else begin
                failed = failed + 1;
                $display("[FAIL] FLAGS count=%0d expected=%0d full=%b empty=%b",
                         count, expected_count, full, empty);
            end
        end
    endtask

    task automatic transaction(
        input reg write_request,
        input reg read_request,
        input reg [DW-1:0] value
    );
        reg actual_write;
        reg actual_read;
        begin
            @(negedge clk);

            wr_en = write_request;
            rd_en = read_request;
            wr_data = value;

            actual_read = read_request && (expected_count > 0);
            actual_write = write_request &&
                           ((expected_count < DEPTH) || actual_read);

            #1;

            if (actual_read) begin
                if (rd_data === expected_mem[head]) begin
                    passed = passed + 1;
                end
                else begin
                    failed = failed + 1;
                    $display("[FAIL] DATA expected=%h got=%h",
                             expected_mem[head], rd_data);
                end
            end

            @(posedge clk);
            #1;

            if (actual_read)
                head = (head + 1) % DEPTH;

            if (actual_write) begin
                expected_mem[tail] = value;
                tail = (tail + 1) % DEPTH;
            end

            expected_count = expected_count +
                             actual_write - actual_read;

            check_flags();

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
            expected_count = 0;

            #1;
            check_flags();

            @(negedge clk);
            rst_n = 1;
        end
    endtask

    initial begin
        $dumpfile("sim/day3_fifo.vcd");
        $dumpvars(0, tb_fifo_day3);

        $display("================================");
        $display("DAY 3 - FIFO BOUNDARY TEST");
        $display("================================");

        reset_fifo();

        // Test 1: Fill FIFO completely
        for (i = 0; i < DEPTH; i = i + 1)
            transaction(1, 0, i + 8'h10);

        // Test 2: Attempt overflow
        transaction(1, 0, 8'hFF);

        // Test 3: Simultaneous read/write when full
        for (i = 0; i < 8; i = i + 1)
            transaction(1, 1, i + 8'h80);

        // Test 4: Drain FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            transaction(0, 1, 0);

        // Test 5: Attempt underflow
        transaction(0, 1, 0);

        // Test 6: Simultaneous request when empty
        transaction(1, 1, 8'hA5);
        transaction(0, 1, 0);

        // Test 7: Pointer wraparound
        for (i = 0; i < 48; i = i + 1) begin
            transaction(1, 0, i);
            transaction(0, 1, 0);
        end

        // Test 8: Reset while FIFO contains data
        for (i = 0; i < 5; i = i + 1)
            transaction(1, 0, i + 8'hC0);

        reset_fifo();

        transaction(1, 0, 8'h5A);
        transaction(0, 1, 0);

        $display("================================");
        $display("DAY 3: PASSED=%0d FAILED=%0d", passed, failed);
        $display("================================");

        if (failed != 0)
            $fatal(1, "DAY 3 FAILED");

        $display("DAY 3 TEST PASSED");
        $finish;
    end

endmodule

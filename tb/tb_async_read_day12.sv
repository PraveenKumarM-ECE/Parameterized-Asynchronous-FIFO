`timescale 1ns/1ps

module tb_async_read_day12;

    localparam integer AW = 4;
    localparam integer PW = AW + 1;
    localparam integer DEPTH = (1 << AW);
    localparam integer MODULUS = (1 << PW);

    reg rd_clk = 0;
    reg rd_rst_n = 0;
    reg rd_en = 0;

    reg [PW-1:0] wr_gray_sync = 0;

    wire [AW-1:0] rd_addr;
    wire [PW-1:0] rd_binary;
    wire [PW-1:0] rd_gray;
    wire empty;

    integer expected_binary = 0;
    integer write_binary = 0;

    integer accepted_reads = 0;
    integer blocked_reads = 0;
    integer passed = 0;
    integer failed = 0;
    integer i;

    reg expected_empty = 1;
    reg [PW-1:0] previous_gray;
    reg [PW-1:0] difference;
    reg [PW-1:0] expected_gray;
    reg accepted;

    async_fifo_read_ptr #(
        .ADDR_WIDTH(AW)
    ) dut (
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),
        .wr_gray_sync(wr_gray_sync),
        .rd_addr(rd_addr),
        .rd_binary(rd_binary),
        .rd_gray(rd_gray),
        .empty(empty)
    );

    always #5 rd_clk = ~rd_clk;

    function automatic [PW-1:0] bin2gray(
        input [PW-1:0] value
    );
        bin2gray = value ^ (value >> 1);
    endfunction

    task automatic check_state;
        begin
            expected_gray = bin2gray(PW'(expected_binary));

            if ((rd_binary === PW'(expected_binary)) &&
                (rd_gray === expected_gray) &&
                (rd_addr === AW'(expected_binary)) &&
                (empty === expected_empty))
                passed = passed + 1;
            else begin
                failed = failed + 1;

                $display(
                    "[FAIL] RD=%0d Expected=%0d Empty=%b ExpectedEmpty=%b",
                    rd_binary,
                    expected_binary,
                    empty,
                    expected_empty
                );
            end
        end
    endtask

    task automatic read_step(
        input reg request
    );
        begin
            @(negedge rd_clk);

            rd_en = request;
            previous_gray = rd_gray;

            accepted = request && !expected_empty;

            @(posedge rd_clk);
            #1;

            if (accepted) begin
                expected_binary =
                    (expected_binary + 1) % MODULUS;

                accepted_reads = accepted_reads + 1;
            end
            else if (request)
                blocked_reads = blocked_reads + 1;

            expected_empty = (
                bin2gray(PW'(expected_binary)) ==
                bin2gray(PW'(write_binary))
            );

            check_state();

            difference = previous_gray ^ rd_gray;

            if (accepted) begin
                if ((difference != 0) &&
                    ((difference & (difference - 1'b1)) == 0))
                    passed = passed + 1;
                else begin
                    failed = failed + 1;
                    $display("[FAIL] Invalid Gray transition");
                end
            end
            else begin
                if (difference == 0)
                    passed = passed + 1;
                else begin
                    failed = failed + 1;
                    $display("[FAIL] Pointer moved without valid read");
                end
            end
        end
    endtask

    task automatic update_write_pointer(
        input integer new_write_binary
    );
        begin
            @(negedge rd_clk);

            rd_en = 0;

            write_binary = new_write_binary % MODULUS;
            wr_gray_sync = bin2gray(PW'(write_binary));

            @(posedge rd_clk);
            #1;

            expected_empty = (
                expected_binary == write_binary
            );

            check_state();
        end
    endtask

    task automatic reset_read;
        begin
            @(negedge rd_clk);

            rd_rst_n = 0;
            rd_en = 0;
            wr_gray_sync = 0;

            expected_binary = 0;
            write_binary = 0;
            expected_empty = 1;

            #1;
            check_state();

            @(negedge rd_clk);
            rd_rst_n = 1;
        end
    endtask

    initial begin
        $dumpfile("sim/day12_async_read.vcd");
        $dumpvars(0, tb_async_read_day12);

        $display("======================================");
        $display("DAY 12 - ASYNC FIFO READ POINTER");
        $display("======================================");

        // Test 1: Initial reset
        reset_read();

        // Test 2: Block reads while empty
        for (i = 0; i < 8; i = i + 1)
            read_step(1);

        // Test 3: Simulate 16 available entries
        update_write_pointer(DEPTH);

        // Test 4: Read all 16 entries
        for (i = 0; i < DEPTH; i = i + 1)
            read_step(1);

        // Test 5: Empty protection
        for (i = 0; i < 4; i = i + 1)
            read_step(1);

        // Test 6: Simulate 8 new entries
        update_write_pointer(24);

        // Test 7: Read 8 entries
        for (i = 0; i < 8; i = i + 1)
            read_step(1);

        // Test 8: Simulate 16 more entries
        update_write_pointer(8);

        // Test 9: Read 16 entries with pointer wraparound
        for (i = 0; i < DEPTH; i = i + 1)
            read_step(1);

        // Test 10: Reset during operation
        reset_read();

        // Test 11: Recovery after reset
        update_write_pointer(6);

        for (i = 0; i < 6; i = i + 1)
            read_step(1);

        $display("--------------------------------------");
        $display("ACCEPTED READS = %0d", accepted_reads);
        $display("BLOCKED READS  = %0d", blocked_reads);
        $display("PASSED CHECKS  = %0d", passed);
        $display("FAILED CHECKS  = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 12 FAILED");

        if (accepted_reads != 46 || blocked_reads != 12)
            $fatal(1, "DAY 12 COVERAGE FAILED");

        $display("DAY 12 TEST PASSED");
        $finish;
    end

endmodule

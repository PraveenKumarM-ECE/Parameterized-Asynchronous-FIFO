`timescale 1ns/1ps

module tb_async_write_day11;

    localparam integer AW = 4;
    localparam integer PW = AW + 1;
    localparam integer DEPTH = (1 << AW);
    localparam integer MODULUS = (1 << PW);

    reg wr_clk = 0;
    reg wr_rst_n = 0;
    reg wr_en = 0;

    reg [PW-1:0] rd_gray_sync = 0;

    wire [AW-1:0] wr_addr;
    wire [PW-1:0] wr_binary;
    wire [PW-1:0] wr_gray;
    wire full;

    integer expected_binary = 0;
    integer read_binary = 0;
    integer accepted_writes = 0;
    integer blocked_writes = 0;
    integer passed = 0;
    integer failed = 0;
    integer i;

    reg expected_full = 0;
    reg [PW-1:0] previous_gray;
    reg [PW-1:0] difference;
    reg [PW-1:0] expected_gray;
    reg [PW-1:0] read_gray;
    reg accepted;

    async_fifo_write_ptr #(
        .ADDR_WIDTH(AW)
    ) dut (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),
        .rd_gray_sync(rd_gray_sync),
        .wr_addr(wr_addr),
        .wr_binary(wr_binary),
        .wr_gray(wr_gray),
        .full(full)
    );

    always #5 wr_clk = ~wr_clk;

    function automatic [PW-1:0] bin2gray(
        input [PW-1:0] value
    );
        bin2gray = value ^ (value >> 1);
    endfunction

    task automatic check_state;
        begin
            expected_gray = bin2gray(PW'(expected_binary));

            if ((wr_binary === PW'(expected_binary)) &&
                (wr_gray === expected_gray) &&
                (wr_addr === AW'(expected_binary)) &&
                (full === expected_full))
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] WR=%0d Expected=%0d Full=%b ExpectedFull=%b",
                    wr_binary, expected_binary, full, expected_full
                );
            end
        end
    endtask

    task automatic write_step(
        input reg request
    );
        begin
            @(negedge wr_clk);

            wr_en = request;
            previous_gray = wr_gray;

            accepted = request && !expected_full;

            @(posedge wr_clk);
            #1;

            if (accepted) begin
                expected_binary = (expected_binary + 1) % MODULUS;
                accepted_writes = accepted_writes + 1;
            end
            else if (request)
                blocked_writes = blocked_writes + 1;

            read_gray = bin2gray(PW'(read_binary));

            expected_full = (
                bin2gray(PW'(expected_binary)) ==
                {~read_gray[AW:AW-1], read_gray[AW-2:0]}
            );

            check_state();

            difference = previous_gray ^ wr_gray;

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
                    $display("[FAIL] Pointer moved without accepted write");
                end
            end
        end
    endtask

    task automatic reset_write;
        begin
            @(negedge wr_clk);

            wr_rst_n = 0;
            wr_en = 0;
            rd_gray_sync = 0;

            expected_binary = 0;
            read_binary = 0;
            expected_full = 0;

            #1;
            check_state();

            @(negedge wr_clk);
            wr_rst_n = 1;
        end
    endtask

    initial begin
        $dumpfile("sim/day11_async_write.vcd");
        $dumpvars(0, tb_async_write_day11);

        $display("======================================");
        $display("DAY 11 - ASYNC FIFO WRITE POINTER");
        $display("======================================");

        // Test 1: Reset
        reset_write();

        // Test 2: Fill all 16 locations
        for (i = 0; i < DEPTH; i = i + 1)
            write_step(1);

        // Test 3: Block writes when full
        for (i = 0; i < 8; i = i + 1)
            write_step(1);

        // Test 4: Simulate read pointer moving by 8
        @(negedge wr_clk);
        read_binary = 8;
        rd_gray_sync = bin2gray(PW'(read_binary));

        // Registered full flag updates at next write clock
        wr_en = 0;
        @(posedge wr_clk);
        #1;

        expected_full = 0;
        check_state();

        // Test 5: Write 8 additional entries
        for (i = 0; i < 8; i = i + 1)
            write_step(1);

        // Test 6: More blocked writes
        for (i = 0; i < 4; i = i + 1)
            write_step(1);

        // Test 7: Advance read pointer and wrap write pointer
        @(negedge wr_clk);
        read_binary = 24;
        rd_gray_sync = bin2gray(PW'(read_binary));
        wr_en = 0;

        @(posedge wr_clk);
        #1;

        expected_full = 0;
        check_state();

        for (i = 0; i < 16; i = i + 1)
            write_step(1);

        // Test 8: Reset during operation
        reset_write();

        // Test 9: Recovery
        for (i = 0; i < 6; i = i + 1)
            write_step(1);

        $display("--------------------------------------");
        $display("ACCEPTED WRITES = %0d", accepted_writes);
        $display("BLOCKED WRITES  = %0d", blocked_writes);
        $display("PASSED CHECKS   = %0d", passed);
        $display("FAILED CHECKS   = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 11 FAILED");

        if (accepted_writes != 46 || blocked_writes != 12)
            $fatal(1, "DAY 11 COVERAGE FAILED");

        $display("DAY 11 TEST PASSED");
        $finish;
    end

endmodule

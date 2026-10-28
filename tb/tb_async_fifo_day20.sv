`timescale 1ns/1ps

module tb_async_fifo_day20;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer DEPTH = (1 << AW);
    localparam integer PW = AW + 1;
    localparam integer TOTAL = 128;

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

    integer cov_full = 0;
    integer cov_empty = 0;
    integer cov_overflow = 0;
    integer cov_underflow = 0;
    integer cov_simultaneous = 0;
    integer cov_wraparound = 0;
    integer cov_reset = 0;

    integer wr_attempts = 0;
    integer rd_attempts = 0;

    reg [PW-1:0] prev_wr_bin;
    reg [PW-1:0] prev_rd_bin;
    reg [PW-1:0] prev_wr_gray;
    reg [PW-1:0] prev_rd_gray;

    reg prev_full;
    reg prev_empty;
    reg prev_wr_en;
    reg prev_rd_en;

    reg [PW-1:0] gray_diff;

    integer i;

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

    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    task automatic check(
        input reg condition,
        input string description
    );
        begin
            if (condition) begin
                passed = passed + 1;
            end else begin
                failed = failed + 1;
                $display("[FAIL] %s at %0t",
                         description, $time);
            end
        end
    endtask

    // Write-domain assertions
    always @(posedge wr_clk) begin
        if (wr_rst_n) begin

            prev_wr_bin = dut.u_write_ptr.wr_binary;
            prev_wr_gray = dut.wr_gray;
            prev_full = full;
            prev_wr_en = wr_en;

            if (full)
                cov_full = cov_full + 1;

            if (wr_en && full)
                cov_overflow = cov_overflow + 1;

            if (wr_en && !full)
                wr_attempts = wr_attempts + 1;

            #1;

            if (prev_wr_en && !prev_full) begin

                gray_diff = prev_wr_gray ^ dut.wr_gray;

                assert (
                    (gray_diff != 0) &&
                    ((gray_diff & (gray_diff - 1'b1)) == 0)
                ) else begin
                    failed = failed + 1;
                    $display("[ASSERT FAIL] Write Gray transition");
                end

                passed = passed + 1;

            end

            if (prev_wr_en && prev_full) begin

                assert (
                    dut.u_write_ptr.wr_binary === prev_wr_bin
                ) else begin
                    failed = failed + 1;
                    $display("[ASSERT FAIL] Overflow pointer changed");
                end

                passed = passed + 1;

            end

        end
    end

    // Read-domain assertions
    always @(posedge rd_clk) begin
        if (rd_rst_n) begin

            prev_rd_bin = dut.u_read_ptr.rd_binary;
            prev_rd_gray = dut.rd_gray;
            prev_empty = empty;
            prev_rd_en = rd_en;

            if (empty)
                cov_empty = cov_empty + 1;

            if (rd_en && empty)
                cov_underflow = cov_underflow + 1;

            if (rd_en && !empty)
                rd_attempts = rd_attempts + 1;

            #1;

            if (prev_rd_en && !prev_empty) begin

                gray_diff = prev_rd_gray ^ dut.rd_gray;

                assert (
                    (gray_diff != 0) &&
                    ((gray_diff & (gray_diff - 1'b1)) == 0)
                ) else begin
                    failed = failed + 1;
                    $display("[ASSERT FAIL] Read Gray transition");
                end

                passed = passed + 1;

            end

            if (prev_rd_en && prev_empty) begin

                assert (
                    dut.u_read_ptr.rd_binary === prev_rd_bin
                ) else begin
                    failed = failed + 1;
                    $display("[ASSERT FAIL] Underflow pointer changed");
                end

                passed = passed + 1;

            end

        end
    end

    // Simultaneous traffic coverage
    always @(posedge wr_clk) begin
        if (wr_rst_n && rd_rst_n &&
            wr_en && rd_en && !full && !empty)
            cov_simultaneous = cov_simultaneous + 1;
    end

    task automatic write_byte(
        input reg [DW-1:0] value
    );
        begin
            @(negedge wr_clk);

            while (full)
                @(negedge wr_clk);

            wr_en = 1;
            wr_data = value;

            @(posedge wr_clk);
            #2;

            writes = writes + 1;

            if ((writes % DEPTH) == 0)
                cov_wraparound = cov_wraparound + 1;

            @(negedge wr_clk);
            wr_en = 0;
        end
    endtask

    task automatic read_byte(
        input reg [DW-1:0] expected
    );
        begin
            @(negedge rd_clk);

            while (empty)
                @(negedge rd_clk);

            rd_en = 1;
            #1;

            check(rd_data === expected,
                  "FIFO scoreboard data");

            @(posedge rd_clk);
            #2;

            reads = reads + 1;

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/day20_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day20);

        $display("======================================");
        $display("DAY 20 - ASSERTIONS AND COVERAGE");
        $display("======================================");

        repeat (5) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        cov_reset = cov_reset + 1;

        repeat (4) @(posedge rd_clk);

        // Test 1: Underflow attempts
        @(negedge rd_clk);
        rd_en = 1;

        repeat (4) @(posedge rd_clk);
        #2;

        @(negedge rd_clk);
        rd_en = 0;

        // Test 2: Fill FIFO
        for (i = 0; i < DEPTH; i = i + 1) begin
            scoreboard[i] = DW'(i + 1);
            write_byte(scoreboard[i]);
        end

        // Test 3: Overflow attempts
        @(negedge wr_clk);
        wr_en = 1;
        wr_data = 8'hFF;

        repeat (4) @(posedge wr_clk);
        #2;

        @(negedge wr_clk);
        wr_en = 0;

        // Test 4: Drain FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(scoreboard[i]);

        // Test 5: Additional wraparound traffic
        for (i = DEPTH; i < TOTAL; i = i + 1) begin
            scoreboard[i] = DW'((i * 9 + 5) % 256);
            write_byte(scoreboard[i]);
            read_byte(scoreboard[i]);
        end

        repeat (5) @(posedge rd_clk);
        #2;

        check(empty === 1'b1, "Final FIFO empty");
        check(full === 1'b0, "Final FIFO not full");
        check(writes == TOTAL, "All writes completed");
        check(reads == TOTAL, "All reads completed");

        check(cov_full > 0, "Full coverage");
        check(cov_empty > 0, "Empty coverage");
        check(cov_overflow > 0, "Overflow coverage");
        check(cov_underflow > 0, "Underflow coverage");
        check(cov_wraparound > 0, "Wraparound coverage");
        check(cov_reset > 0, "Reset coverage");

        $display("--------------------------------------");
        $display("WRITES                = %0d", writes);
        $display("READS                 = %0d", reads);
        $display("FULL COVERAGE         = %0d", cov_full);
        $display("EMPTY COVERAGE        = %0d", cov_empty);
        $display("OVERFLOW COVERAGE     = %0d", cov_overflow);
        $display("UNDERFLOW COVERAGE    = %0d", cov_underflow);
        $display("SIMULTANEOUS COVERAGE = %0d", cov_simultaneous);
        $display("WRAPAROUND COVERAGE   = %0d", cov_wraparound);
        $display("RESET COVERAGE        = %0d", cov_reset);
        $display("PASSED CHECKS         = %0d", passed);
        $display("FAILED CHECKS         = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 20 FAILED");

        $display("DAY 20 TEST PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "DAY 20 TIMEOUT");
    end

endmodule

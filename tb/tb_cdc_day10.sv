`timescale 1ns/1ps

module tb_cdc_day10;

    localparam integer WIDTH = 5;
    localparam integer TEST_CYCLES = 500;

    reg src_clk = 0;
    reg dst_clk = 0;
    reg dst_rst_n = 0;

    reg [WIDTH-1:0] src_binary = 0;
    wire [WIDTH-1:0] src_gray;
    wire [WIDTH-1:0] sync_gray;

    reg [WIDTH-1:0] expected_stage1 = 0;
    reg [WIDTH-1:0] expected_stage2 = 0;

    reg [WIDTH-1:0] old_stage1;

    integer passed = 0;
    integer failed = 0;
    integer dst_cycles = 0;
    integer src_updates = 0;
    integer reset_checks = 0;

    bin_to_gray #(
        .WIDTH(WIDTH)
    ) converter (
        .bin(src_binary),
        .gray(src_gray)
    );

    cdc_sync #(
        .WIDTH(WIDTH)
    ) dut (
        .dst_clk(dst_clk),
        .dst_rst_n(dst_rst_n),
        .async_gray(src_gray),
        .sync_gray(sync_gray)
    );

    // Source clock: 14 ns period
    always #7 src_clk = ~src_clk;

    // Destination clock: 10 ns period
    always #5 dst_clk = ~dst_clk;

    task automatic check_output;
        begin
            if (sync_gray === expected_stage2)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] Time=%0t Expected=%b Got=%b",
                    $time, expected_stage2, sync_gray
                );
            end
        end
    endtask

    // Source pointer increments on source clock
    always @(posedge src_clk) begin
        if (dst_rst_n && src_updates < 350) begin
            if ($urandom_range(0, 99) < 65) begin
                src_binary <= src_binary + 1'b1;
                src_updates = src_updates + 1;
            end
        end
    end

    // Reference 2-stage pipeline
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            expected_stage1 <= '0;
            expected_stage2 <= '0;
        end
        else begin
            expected_stage1 <= src_gray;
            expected_stage2 <= expected_stage1;
        end
    end

    // Compare after nonblocking assignments settle
    always @(posedge dst_clk) begin
        #1;

        if (dst_rst_n) begin
            dst_cycles = dst_cycles + 1;
            check_output();
        end
    end

    initial begin
        $dumpfile("sim/day10_cdc_sync.vcd");
        $dumpvars(0, tb_cdc_day10);

        $display("======================================");
        $display("DAY 10 - CDC SYNCHRONIZER TEST");
        $display("======================================");

        repeat (4) @(negedge dst_clk);

        dst_rst_n = 1;

        repeat (TEST_CYCLES) @(posedge dst_clk);

        @(negedge dst_clk);

        // Reset during operation
        dst_rst_n = 0;
        src_binary = 0;

        #1;

        if (sync_gray === '0) begin
            passed = passed + 1;
            reset_checks = reset_checks + 1;
        end
        else begin
            failed = failed + 1;
            $display("[FAIL] Reset did not clear output");
        end

        repeat (3) @(negedge dst_clk);
        dst_rst_n = 1;

        repeat (100) @(posedge dst_clk);

        @(negedge dst_clk);

        $display("--------------------------------------");
        $display("DESTINATION CYCLES = %0d", dst_cycles);
        $display("SOURCE UPDATES     = %0d", src_updates);
        $display("RESET CHECKS       = %0d", reset_checks);
        $display("PASSED             = %0d", passed);
        $display("FAILED             = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 10 FAILED");

        if (dst_cycles < 600 || src_updates == 0 || reset_checks == 0)
            $fatal(1, "DAY 10 COVERAGE FAILED");

        $display("DAY 10 TEST PASSED");
        $finish;
    end

endmodule

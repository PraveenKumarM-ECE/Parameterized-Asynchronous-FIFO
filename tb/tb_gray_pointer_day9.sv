`timescale 1ns/1ps

module tb_gray_pointer_day9;

    localparam integer AW = 4;
    localparam integer PW = AW + 1;
    localparam integer MODULUS = (1 << PW);

    reg clk = 0;
    reg rst_n = 0;
    reg enable = 0;

    wire [PW-1:0] binary_ptr;
    wire [PW-1:0] gray_ptr;

    integer expected_binary = 0;
    integer passed = 0;
    integer failed = 0;
    integer increments = 0;
    integer stalls = 0;
    integer transitions = 0;
    integer i;

    reg [PW-1:0] expected_gray;
    reg [PW-1:0] previous_gray;
    reg [PW-1:0] difference;

    gray_pointer_counter #(
        .ADDR_WIDTH(AW)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .binary_ptr(binary_ptr),
        .gray_ptr(gray_ptr)
    );

    always #5 clk = ~clk;

    task automatic check_state;
        begin
            expected_gray = PW'(
                expected_binary ^ (expected_binary >> 1)
            );

            if ((binary_ptr === PW'(expected_binary)) &&
                (gray_ptr === expected_gray))
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display(
                    "[FAIL] Binary=%0d Expected=%0d Gray=%b Expected=%b",
                    binary_ptr, expected_binary,
                    gray_ptr, expected_gray
                );
            end
        end
    endtask

    task automatic step(
        input reg step_enable
    );
        begin
            @(negedge clk);
            enable = step_enable;
            previous_gray = gray_ptr;

            @(posedge clk);
            #1;

            if (step_enable) begin
                expected_binary = (expected_binary + 1) % MODULUS;
                increments = increments + 1;
            end
            else
                stalls = stalls + 1;

            check_state();

            difference = previous_gray ^ gray_ptr;

            if (step_enable) begin
                if ((difference != 0) &&
                    ((difference & (difference - 1'b1)) == 0))
                    passed = passed + 1;
                else begin
                    failed = failed + 1;
                    $display("[FAIL] Invalid Gray transition");
                end

                transitions = transitions + 1;
            end
            else begin
                if (difference == 0)
                    passed = passed + 1;
                else begin
                    failed = failed + 1;
                    $display("[FAIL] Gray changed during stall");
                end
            end
        end
    endtask

    task automatic reset_counter;
        begin
            @(negedge clk);
            rst_n = 0;
            enable = 0;
            expected_binary = 0;

            #1;
            check_state();

            @(negedge clk);
            rst_n = 1;
        end
    endtask

    initial begin
        $dumpfile("sim/day9_gray_pointer.vcd");
        $dumpvars(0, tb_gray_pointer_day9);

        $display("======================================");
        $display("DAY 9 - GRAY POINTER VERIFICATION");
        $display("======================================");

        // Initial reset
        reset_counter();

        // 256 increments: covers multiple wraparounds
        for (i = 0; i < 256; i = i + 1)
            step(1);

        // 32 stalls
        for (i = 0; i < 32; i = i + 1)
            step(0);

        // 128 randomized enable cycles
        for (i = 0; i < 128; i = i + 1)
            step($urandom_range(0, 1));

        // Reset during operation
        reset_counter();

        // Recovery after reset
        for (i = 0; i < 16; i = i + 1)
            step(1);

        $display("--------------------------------------");
        $display("INCREMENTS  = %0d", increments);
        $display("STALLS      = %0d", stalls);
        $display("TRANSITIONS = %0d", transitions);
        $display("PASSED      = %0d", passed);
        $display("FAILED      = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 9 FAILED");

        if (increments < 272 || stalls < 32)
            $fatal(1, "DAY 9 COVERAGE FAILED");

        $display("DAY 9 TEST PASSED");
        $finish;
    end

endmodule

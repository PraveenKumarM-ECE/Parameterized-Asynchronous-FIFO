`timescale 1ns/1ps

module tb_gray_day8;

    localparam integer WIDTH = 5;
    localparam integer VALUES = (1 << WIDTH);

    reg  [WIDTH-1:0] binary_in = 0;
    reg  [WIDTH-1:0] gray_in = 0;

    wire [WIDTH-1:0] gray_out;
    wire [WIDTH-1:0] binary_out;

    integer passed = 0;
    integer failed = 0;
    integer i;

    reg [WIDTH-1:0] expected_gray;
    reg [WIDTH-1:0] previous_gray;
    reg [WIDTH-1:0] difference;

    bin_to_gray #(
        .WIDTH(WIDTH)
    ) u_bin_to_gray (
        .bin(binary_in),
        .gray(gray_out)
    );

    gray_to_bin #(
        .WIDTH(WIDTH)
    ) u_gray_to_bin (
        .gray(gray_in),
        .bin(binary_out)
    );

    task automatic check(
        input reg condition,
        input string description
    );
        begin
            if (condition)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display("[FAIL] %s", description);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/day8_gray_conversion.vcd");
        $dumpvars(0, tb_gray_day8);

        $display("======================================");
        $display("DAY 8 - GRAY CODE VERIFICATION");
        $display("======================================");

        previous_gray = 0;

        // Test 1: All binary-to-Gray conversions
        for (i = 0; i < VALUES; i = i + 1) begin

            binary_in = WIDTH'(i);
            expected_gray = WIDTH'(i ^ (i >> 1));

            #1;

            check(
                gray_out === expected_gray,
                "Binary-to-Gray conversion"
            );

            // Check adjacent Gray values differ by one bit
            if (i > 0) begin

                difference = gray_out ^ previous_gray;

                check(
                    (difference != 0) &&
                    ((difference & (difference - 1'b1)) == 0),
                    "Single-bit Gray transition"
                );

            end

            previous_gray = gray_out;

        end

        // Test 2: All Gray-to-binary conversions
        for (i = 0; i < VALUES; i = i + 1) begin

            gray_in = WIDTH'(i ^ (i >> 1));

            #1;

            check(
                binary_out === WIDTH'(i),
                "Gray-to-Binary conversion"
            );

        end

        // Test 3: Gray-code wraparound transition
        binary_in = WIDTH'(VALUES - 1);
        #1;
        previous_gray = gray_out;

        binary_in = 0;
        #1;

        difference = previous_gray ^ gray_out;

        check(
            (difference != 0) &&
            ((difference & (difference - 1'b1)) == 0),
            "Gray-code wraparound"
        );

        // Test 4: Zero conversion
        binary_in = 0;
        gray_in = 0;
        #1;

        check(
            gray_out === 0 && binary_out === 0,
            "Zero conversion"
        );

        $display("--------------------------------------");
        $display("WIDTH         = %0d", WIDTH);
        $display("VALUES TESTED = %0d", VALUES);
        $display("PASSED        = %0d", passed);
        $display("FAILED        = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 8 FAILED");

        $display("DAY 8 TEST PASSED");
        $finish;
    end

endmodule

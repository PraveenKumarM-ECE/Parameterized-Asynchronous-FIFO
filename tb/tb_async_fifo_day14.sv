`timescale 1ns/1ps

module tb_async_fifo_day14;

    localparam integer DW = 8;
    localparam integer AW = 4;
    localparam integer DEPTH = (1 << AW);
    localparam integer PW = AW + 1;

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

    integer passed = 0;
    integer failed = 0;
    integer writes = 0;
    integer reads = 0;
    integer i;

    reg [PW-1:0] previous_wr_gray;
    reg [PW-1:0] previous_rd_gray;
    reg [PW-1:0] diff;

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

    // Independent clock frequencies
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    task automatic check(
        input reg condition,
        input string description
    );
        begin
            if (condition)
                passed = passed + 1;
            else begin
                failed = failed + 1;
                $display("[FAIL] %s at %0t",
                         description, $time);
            end
        end
    endtask

    task automatic write_byte(
        input reg [DW-1:0] value
    );
        begin
            @(negedge wr_clk);

            while (full)
                @(negedge wr_clk);

            previous_wr_gray = dut.wr_gray;

            wr_en = 1;
            wr_data = value;

            @(posedge wr_clk);
            #1;

            writes = writes + 1;

            diff = previous_wr_gray ^ dut.wr_gray;

            check(
                (diff != 0) &&
                ((diff & (diff - 1'b1)) == 0),
                "Write Gray pointer transition"
            );

            @(negedge wr_clk);
            wr_en = 0;
        end
    endtask

    task automatic read_byte(
        input reg [DW-1:0] expected
    );
        reg [DW-1:0] observed;
        reg [PW-1:0] local_diff;
        begin
            @(negedge rd_clk);

            while (empty)
                @(negedge rd_clk);

            previous_rd_gray = dut.rd_gray;

            rd_en = 1;
            #1;

            observed = rd_data;

            check(
                observed === expected,
                "FIFO data integrity"
            );

            @(posedge rd_clk);
            #1;

            reads = reads + 1;

            local_diff = previous_rd_gray ^ dut.rd_gray;

            check(
                (local_diff != 0) &&
                ((local_diff & (local_diff - 1'b1)) == 0),
                "Read Gray pointer transition"
            );

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    task automatic reset_fifo;
        begin
            @(negedge wr_clk);

            wr_en = 0;
            rd_en = 0;

            wr_rst_n = 0;
            rd_rst_n = 0;

            #1;

            check(full === 1'b0, "Full cleared by reset");
            check(empty === 1'b1, "Empty asserted by reset");

            repeat (4) @(negedge wr_clk);

            wr_rst_n = 1;
            rd_rst_n = 1;

            repeat (4) @(posedge rd_clk);
        end
    endtask

    initial begin
        $dumpfile("sim/day14_cdc.vcd");
        $dumpvars(0, tb_async_fifo_day14);

        $display("======================================");
        $display("DAY 14 - ASYNC FIFO CDC VERIFICATION");
        $display("======================================");

        // Test 1: Reset
        reset_fifo();

        // Test 2: Fill FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DW'(i + 1));

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1, "FIFO full");

        // Test 3: Read all entries
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(DW'(i + 1));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "FIFO empty");

        // Test 4: Pointer wraparound
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DW'(i + 50));

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1, "Full after wraparound");

        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(DW'(i + 50));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "Empty after wraparound");

        // Test 5: Reset during operation
        for (i = 0; i < 5; i = i + 1)
            write_byte(DW'(i + 100));

        reset_fifo();

        // Test 6: Recovery after reset
        for (i = 0; i < 8; i = i + 1)
            write_byte(DW'(i + 150));

        for (i = 0; i < 8; i = i + 1)
            read_byte(DW'(i + 150));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "Empty after reset recovery");

        $display("--------------------------------------");
        $display("WRITES        = %0d", writes);
        $display("READS         = %0d", reads);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 14 FAILED");

        if (writes != 45 || reads != 40)
            $fatal(1, "DAY 14 COVERAGE FAILED");

        $display("DAY 14 TEST PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "DAY 14 TIMEOUT");
    end

endmodule

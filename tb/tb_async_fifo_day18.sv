`timescale 1ns/1ps

module tb_async_fifo_day18;

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
    integer resets = 0;
    integer i;

    reg [DW-1:0] observed;

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

    // Assert both resets together, then release
    // each reset on its respective clock edge.
    task automatic reset_fifo;
        begin
            @(negedge wr_clk);

            wr_en = 0;
            rd_en = 0;

            wr_rst_n = 0;
            rd_rst_n = 0;

            #1;

            check(full === 1'b0,
                  "Full cleared by reset");

            check(empty === 1'b1,
                  "Empty asserted by reset");

            check(dut.u_write_ptr.wr_binary === {PW{1'b0}},
                  "Write binary pointer cleared");

            check(dut.u_read_ptr.rd_binary === {PW{1'b0}},
                  "Read binary pointer cleared");

            check(dut.wr_gray === {PW{1'b0}},
                  "Write Gray pointer cleared");

            check(dut.rd_gray === {PW{1'b0}},
                  "Read Gray pointer cleared");

            repeat (4) @(negedge wr_clk);

            wr_rst_n = 1;

            @(negedge rd_clk);
            rd_rst_n = 1;

            repeat (4) @(posedge rd_clk);
            #1;

            check(empty === 1'b1,
                  "Empty stable after reset release");

            check(full === 1'b0,
                  "Full stable after reset release");

            resets = resets + 1;
        end
    endtask

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
            #1;

            writes = writes + 1;

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

            observed = rd_data;

            check(observed === expected,
                  "Data integrity after reset");

            @(posedge rd_clk);
            #1;

            reads = reads + 1;

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/day18_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day18);

        $display("======================================");
        $display("DAY 18 - RESET AND RECOVERY TEST");
        $display("======================================");

        // TEST 1: Initial reset
        reset_fifo();

        // TEST 2: Reset when FIFO is partially filled
        for (i = 0; i < 8; i = i + 1)
            write_byte(DW'(i + 10));

        reset_fifo();

        // TEST 3: Recovery after partial-fill reset
        for (i = 0; i < 8; i = i + 1)
            write_byte(DW'(i + 40));

        for (i = 0; i < 8; i = i + 1)
            read_byte(DW'(i + 40));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "Empty after partial-reset recovery");

        // TEST 4: Reset when FIFO is full
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DW'(i + 80));

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1,
              "FIFO full before reset");

        reset_fifo();

        // TEST 5: Recovery after full reset
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DW'(i + 120));

        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(DW'(i + 120));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "Empty after full-reset recovery");

        // TEST 6: Repeated reset cycles
        repeat (3)
            reset_fifo();

        // TEST 7: Final recovery
        for (i = 0; i < 8; i = i + 1)
            write_byte(DW'(i + 200));

        for (i = 0; i < 8; i = i + 1)
            read_byte(DW'(i + 200));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "Empty after final recovery");

        check(full === 1'b0,
              "Not full after final recovery");

        check(resets == 6,
              "All reset cycles completed");

        check(writes == 56,
              "Expected write transactions");

        check(reads == 32,
              "Expected read transactions");

        $display("--------------------------------------");
        $display("RESET CYCLES  = %0d", resets);
        $display("TOTAL WRITES  = %0d", writes);
        $display("TOTAL READS   = %0d", reads);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 18 FAILED");

        $display("DAY 18 TEST PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "DAY 18 TIMEOUT");
    end

endmodule

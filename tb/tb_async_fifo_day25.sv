`timescale 1ns/1ps

module tb_async_fifo_day25;

    parameter integer DW = 8;
    parameter integer AW = 4;
    parameter integer TOTAL = 128;

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

    reg [DW-1:0] scoreboard [0:TOTAL-1];

    integer writes = 0;
    integer reads = 0;
    integer passed = 0;
    integer failed = 0;

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

            check(
                observed === expected,
                "Parameterized FIFO data integrity"
            );

            @(posedge rd_clk);
            #1;

            reads = reads + 1;

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/day25_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day25);

        $display("======================================");
        $display("DAY 25 - PARAMETERIZED FIFO TEST");
        $display("======================================");

        $display("DATA_WIDTH = %0d", DW);
        $display("ADDR_WIDTH = %0d", AW);
        $display("DEPTH      = %0d", DEPTH);

        repeat (5) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "Empty after reset");

        check(full === 1'b0,
              "Not full after reset");

        // Phase 1: Fill FIFO to capacity.
        for (i = 0; i < DEPTH; i = i + 1) begin
            scoreboard[i] = DW'(i * 17 + 3);
            write_byte(scoreboard[i]);
        end

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1,
              "Full at configured depth");

        // Phase 2: Drain FIFO.
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(scoreboard[i]);

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "Empty after full drain");

        // Phase 3: Exercise pointer wraparound.
        for (i = DEPTH; i < TOTAL; i = i + 1) begin
            scoreboard[i] = DW'(i * 29 + 11);
            write_byte(scoreboard[i]);
            read_byte(scoreboard[i]);
        end

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1,
              "Empty after wraparound traffic");

        check(full === 1'b0,
              "Not full after wraparound traffic");

        check(writes == TOTAL,
              "All writes completed");

        check(reads == TOTAL,
              "All reads completed");

        $display("--------------------------------------");
        $display("DATA_WIDTH    = %0d", DW);
        $display("FIFO DEPTH    = %0d", DEPTH);
        $display("WRITES        = %0d", writes);
        $display("READS         = %0d", reads);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 25 FAILED");

        $display("DAY 25 TEST PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "DAY 25 TIMEOUT");
    end

endmodule

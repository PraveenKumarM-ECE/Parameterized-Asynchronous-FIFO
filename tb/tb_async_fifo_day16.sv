`timescale 1ns/1ps

module tb_async_fifo_day16;

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
    integer accepted_writes = 0;
    integer accepted_reads = 0;
    integer i;

    reg [PW-1:0] saved_pointer;
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

    // Independent clocks
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
                $display("[FAIL] %s at %0t", description, $time);
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

            accepted_writes = accepted_writes + 1;

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

            check(observed === expected, "FIFO data order");

            @(posedge rd_clk);
            #1;

            accepted_reads = accepted_reads + 1;

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/day16_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day16);

        $display("======================================");
        $display("DAY 16 - FIFO BOUNDARY VERIFICATION");
        $display("======================================");

        // Reset
        repeat (4) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "FIFO empty after reset");
        check(full === 1'b0, "FIFO not full after reset");

        // Test 1: Underflow protection
        saved_pointer = dut.u_read_ptr.rd_binary;

        @(negedge rd_clk);
        rd_en = 1;

        repeat (5) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "Empty remains asserted");
        check(dut.u_read_ptr.rd_binary === saved_pointer,
              "Read pointer unchanged during underflow");

        @(negedge rd_clk);
        rd_en = 0;

        // Test 2: Fill FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DW'(i + 10));

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1, "Full asserted at capacity");
        check(empty === 1'b0, "FIFO not empty when full");

        // Test 3: Overflow protection
        saved_pointer = dut.u_write_ptr.wr_binary;

        @(negedge wr_clk);
        wr_en = 1;
        wr_data = 8'hFF;

        repeat (5) @(posedge wr_clk);
        #1;

        check(full === 1'b1, "Full remains asserted");
        check(dut.u_write_ptr.wr_binary === saved_pointer,
              "Write pointer unchanged during overflow");

        @(negedge wr_clk);
        wr_en = 0;

        // Test 4: Drain FIFO and check data integrity
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(DW'(i + 10));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "Empty asserted after drain");
        check(full === 1'b0, "Full cleared after drain");

        // Test 5: Recovery after overflow/underflow
        for (i = 0; i < 8; i = i + 1)
            write_byte(DW'(i + 100));

        for (i = 0; i < 8; i = i + 1)
            read_byte(DW'(i + 100));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "Empty after recovery");
        check(full === 1'b0, "Not full after recovery");

        $display("--------------------------------------");
        $display("ACCEPTED WRITES = %0d", accepted_writes);
        $display("ACCEPTED READS  = %0d", accepted_reads);
        $display("PASSED CHECKS   = %0d", passed);
        $display("FAILED CHECKS   = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 16 FAILED");

        if (accepted_writes != 24 || accepted_reads != 24)
            $fatal(1, "DAY 16 COVERAGE FAILED");

        $display("DAY 16 TEST PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "DAY 16 TIMEOUT");
    end

endmodule

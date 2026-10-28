`timescale 1ns/1ps

module tb_async_fifo_day13;

    localparam integer DATA_WIDTH = 8;
    localparam integer ADDR_WIDTH = 4;
    localparam integer DEPTH = (1 << ADDR_WIDTH);

    reg wr_clk = 0;
    reg rd_clk = 0;

    reg wr_rst_n = 0;
    reg rd_rst_n = 0;

    reg wr_en = 0;
    reg rd_en = 0;

    reg [DATA_WIDTH-1:0] wr_data = 0;

    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;

    integer passed = 0;
    integer failed = 0;

    integer writes = 0;
    integer reads = 0;
    integer i;

    reg [DATA_WIDTH-1:0] expected_data;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
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

    // Independent clock domains
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    task automatic check(
        input reg condition,
        input string description
    );
        begin
            if (condition) begin
                passed = passed + 1;
            end
            else begin
                failed = failed + 1;
                $display("[FAIL] %s at time %0t",
                         description, $time);
            end
        end
    endtask

    task automatic write_byte(
        input reg [DATA_WIDTH-1:0] value
    );
        begin
            // Wait until the write domain can accept data
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
        input reg [DATA_WIDTH-1:0] expected
    );
        begin
            @(negedge rd_clk);

            while (empty)
                @(negedge rd_clk);

            rd_en = 1;

            // Read data is available before pointer advances
            #1;
            expected_data = rd_data;

            check(
                expected_data === expected,
                "FIFO data ordering"
            );

            @(posedge rd_clk);
            #1;

            reads = reads + 1;

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/day13_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_day13);

        $display("======================================");
        $display("DAY 13 - ASYNC FIFO INTEGRATION");
        $display("======================================");

        // Reset both clock domains
        repeat (4) @(negedge wr_clk);

        wr_rst_n = 1;
        rd_rst_n = 1;

        repeat (4) @(posedge rd_clk);

        check(empty === 1'b1, "FIFO initially empty");
        check(full === 1'b0, "FIFO initially not full");

        // Test 1: Write 16 bytes
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DATA_WIDTH'(i + 1));

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1, "FIFO full after 16 writes");

        // Test 2: Read all 16 bytes
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(DATA_WIDTH'(i + 1));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "FIFO empty after 16 reads");

        // Test 3: Write another 16 bytes (wraparound)
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(DATA_WIDTH'(i + 50));

        repeat (3) @(posedge wr_clk);
        #1;

        check(full === 1'b1, "FIFO full after wraparound");

        // Test 4: Read another 16 bytes
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte(DATA_WIDTH'(i + 50));

        repeat (4) @(posedge rd_clk);
        #1;

        check(empty === 1'b1, "FIFO empty after wraparound");

        $display("--------------------------------------");
        $display("WRITES        = %0d", writes);
        $display("READS         = %0d", reads);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);
        $display("--------------------------------------");

        if (failed != 0)
            $fatal(1, "DAY 13 FAILED");

        if (writes != 32 || reads != 32)
            $fatal(1, "DAY 13 COVERAGE FAILED");

        $display("DAY 13 TEST PASSED");
        $finish;
    end

    // Simulation timeout
    initial begin
        #100000;
        $fatal(1, "DAY 13 TIMEOUT");
    end

endmodule

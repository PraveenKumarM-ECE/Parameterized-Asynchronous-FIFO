`timescale 1ns/1ps

module tb_fifo_memory;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;

    logic wr_clk = 0;
    logic wr_en = 0;

    logic [ADDR_WIDTH-1:0] wr_addr = 0;
    logic [ADDR_WIDTH-1:0] rd_addr = 0;

    logic [DATA_WIDTH-1:0] wr_data = 0;
    logic [DATA_WIDTH-1:0] rd_data;

    integer passed = 0;
    integer failed = 0;

    fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

    always #5 wr_clk = ~wr_clk;

    task automatic write_data(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
        @(negedge wr_clk);
        wr_en = 1;
        wr_addr = addr;
        wr_data = data;

        @(negedge wr_clk);
        wr_en = 0;
    endtask

    task automatic check_data(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] expected
    );
        rd_addr = addr;
        #1;

        if (rd_data === expected) begin
            passed++;
            $display("[PASS] Address=%0d Data=%h", addr, rd_data);
        end
        else begin
            failed++;
            $display("[FAIL] Address=%0d Expected=%h Got=%h",
                     addr, expected, rd_data);
        end
    endtask

    initial begin
        $dumpfile("sim/day1_fifo_memory.vcd");
        $dumpvars(0, tb_fifo_memory);

        $display("=================================");
        $display("DAY 1 - FIFO MEMORY TEST");
        $display("=================================");

        write_data(0, 8'hA5);
        write_data(1, 8'h3C);
        write_data(2, 8'hF0);
        write_data(15, 8'h55);

        check_data(0, 8'hA5);
        check_data(1, 8'h3C);
        check_data(2, 8'hF0);
        check_data(15, 8'h55);

        write_data(1, 8'h99);
        check_data(1, 8'h99);

        $display("=================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("=================================");

        if (failed == 0) begin
            $display("DAY 1 TEST PASSED");
        end
        else begin
            $fatal(1, "DAY 1 TEST FAILED");
        end

        $finish;
    end

endmodule

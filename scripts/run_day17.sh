#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

run_test() {
    local name="$1"
    local wr_half="$2"
    local rd_half="$3"

    echo "======================================"
    echo "TEST: $name"
    echo "WR_HALF=$wr_half RD_HALF=$rd_half"
    echo "======================================"

    iverilog -g2012 \
    -s tb_async_fifo_day17 \
    -Ptb_async_fifo_day17.WR_HALF="$wr_half" \
    -Ptb_async_fifo_day17.RD_HALF="$rd_half" \
    -o "sim/day17_${name}.vvp" \
    rtl/async_fifo_memory.sv \
    rtl/async_fifo_write_ptr.sv \
    rtl/async_fifo_read_ptr.sv \
    rtl/cdc_sync.sv \
    rtl/async_fifo.sv \
    tb/tb_async_fifo_day17.sv

    vvp "sim/day17_${name}.vvp" \
    | tee "reports/day17_${name}.log"

    grep -q "DAY 17 TEST PASSED" \
    "reports/day17_${name}.log"
}

run_test write_fast 5 10
run_test read_fast 10 5
run_test different_clocks 5 7

echo "======================================"
echo "ALL DAY 17 CLOCK TESTS PASSED"
echo "======================================"

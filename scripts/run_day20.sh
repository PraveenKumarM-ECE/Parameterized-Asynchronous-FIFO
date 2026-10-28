#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

echo "======================================"
echo "DAY 20 - ASSERTIONS AND COVERAGE"
echo "======================================"

iverilog -g2012 \
-s tb_async_fifo_day20 \
-o sim/day20_async_fifo.vvp \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv \
tb/tb_async_fifo_day20.sv

vvp sim/day20_async_fifo.vvp \
| tee reports/day20_verification.log

grep -q "DAY 20 TEST PASSED" \
reports/day20_verification.log

echo "DAY 20 SIMULATION COMPLETE"

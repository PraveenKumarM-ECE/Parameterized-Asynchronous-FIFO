#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

echo "======================================"
echo "DAY 15 - ADVANCED FIFO VERIFICATION"
echo "======================================"

iverilog -g2012 -s tb_async_fifo_day15 \
-o sim/day15_async_fifo.vvp \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv \
tb/tb_async_fifo_day15.sv

vvp sim/day15_async_fifo.vvp | tee reports/day15_verification.log

grep -q "DAY 15 TEST PASSED" reports/day15_verification.log

echo "DAY 15 SIMULATION COMPLETE"

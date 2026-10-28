#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

echo "======================================"
echo "DAY 18 - RESET AND RECOVERY"
echo "======================================"

iverilog -g2012 -s tb_async_fifo_day18 \
-o sim/day18_async_fifo.vvp \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv \
tb/tb_async_fifo_day18.sv

vvp sim/day18_async_fifo.vvp \
| tee reports/day18_verification.log

grep -q "DAY 18 TEST PASSED" \
reports/day18_verification.log

echo "DAY 18 SIMULATION COMPLETE"

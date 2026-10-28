#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

echo "======================================"
echo "DAY 16 - FIFO BOUNDARY VERIFICATION"
echo "======================================"

iverilog -g2012 -s tb_async_fifo_day16 \
-o sim/day16_async_fifo.vvp \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv \
tb/tb_async_fifo_day16.sv

set -o pipefail
vvp sim/day16_async_fifo.vvp | tee reports/day16_verification.log

grep -q "DAY 16 TEST PASSED" reports/day16_verification.log

echo "DAY 16 SIMULATION COMPLETE"

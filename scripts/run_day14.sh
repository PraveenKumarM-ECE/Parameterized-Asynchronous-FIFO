#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

echo "======================================"
echo "DAY 14 - CDC VERIFICATION"
echo "======================================"

iverilog -g2012 -s tb_async_fifo_day14 \
-o sim/day14_cdc.vvp \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv \
tb/tb_async_fifo_day14.sv

vvp sim/day14_cdc.vvp | tee reports/day14_cdc_verification.log

echo "======================================"
echo "DAY 14 SIMULATION COMPLETE"
echo "======================================"

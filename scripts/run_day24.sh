#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p reports

echo "======================================"
echo "DAY 24 - CDC AND TIMING VERIFICATION"
echo "======================================"

echo "[1/3] Validating CDC structure and SDC..."
python3 scripts/check_day24.py

echo "[2/3] Running RTL lint..."
verilator --lint-only -Wall \
    --top-module async_fifo \
    rtl/async_fifo_memory.sv \
    rtl/async_fifo_write_ptr.sv \
    rtl/async_fifo_read_ptr.sv \
    rtl/cdc_sync.sv \
    rtl/async_fifo.sv \
    > reports/day24_lint.log 2>&1

echo "LINT PASSED"

echo "[3/3] Verifying deliverables..."

test -s constraints/async_fifo.sdc
test -s docs/day24_cdc_architecture.md
test -s reports/day24_cdc_validation.log
test -f reports/day24_lint.log

echo "======================================"
echo "DAY 24 CDC DOCUMENTATION PASSED"
echo "======================================"

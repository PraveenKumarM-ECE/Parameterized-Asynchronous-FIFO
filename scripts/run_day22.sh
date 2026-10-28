#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p reports sim

RTL_FILES=(
    rtl/async_fifo_memory.sv
    rtl/async_fifo_write_ptr.sv
    rtl/async_fifo_read_ptr.sv
    rtl/cdc_sync.sv
    rtl/async_fifo.sv
)

echo "======================================"
echo "DAY 22 - RTL LINT AND SYNTHESIS"
echo "======================================"

echo "[1/4] Running Verilator lint..."

verilator --lint-only -Wall \
    --top-module async_fifo \
    "${RTL_FILES[@]}" \
    > reports/day22_lint.log 2>&1

echo "LINT PASSED" | tee -a reports/day22_lint.log

echo "[2/4] Running Yosys synthesis..."

yosys -Q -T -l reports/day22_synthesis.log -p "
read_verilog -sv ${RTL_FILES[*]}
hierarchy -check -top async_fifo
proc
opt
memory
opt
techmap
opt
check -assert
stat
write_verilog -noattr -noexpr sim/day22_async_fifo_netlist.v
"

echo "[3/4] Checking synthesized netlist..."

test -s sim/day22_async_fifo_netlist.v

echo "[4/4] Generating resource summary..."

{
    echo "======================================"
    echo "DAY 22 - HARDWARE RESOURCE SUMMARY"
    echo "======================================"
    echo
    echo "Top Module: async_fifo"
    echo "DATA_WIDTH: 8"
    echo "ADDR_WIDTH: 4"
    echo "FIFO DEPTH: 16"
    echo "FIFO STORAGE: 128 bits"
    echo
    echo "Tools:"
    verilator --version
    yosys -V
    echo
    echo "SYNTHESIS STATISTICS:"
    sed -n '/=== async_fifo ===/,/^$/p' \
        reports/day22_synthesis.log | tail -n 40
    echo
    echo "NETLIST:"
    wc -l sim/day22_async_fifo_netlist.v
    echo
    echo "RESULT: PASS"
} > reports/day22_resource_summary.txt

echo "======================================"
echo "DAY 22 LINT AND SYNTHESIS PASSED"
echo "======================================"

#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

CSV="reports/day25_parameter_verification.csv"

echo "configuration,data_width,addr_width,depth,transfers,status" > "$CSV"

run_config() {
    local name="$1"
    local dw="$2"
    local aw="$3"

    local depth=$((1 << aw))
    local log="reports/day25_${name}.log"

    echo "======================================"
    echo "RUNNING $name: DW=$dw AW=$aw DEPTH=$depth"
    echo "======================================"

    iverilog -g2012 \
        -s tb_async_fifo_day25 \
        -Ptb_async_fifo_day25.DW="$dw" \
        -Ptb_async_fifo_day25.AW="$aw" \
        -o "sim/day25_${name}.vvp" \
        rtl/async_fifo_memory.sv \
        rtl/async_fifo_write_ptr.sv \
        rtl/async_fifo_read_ptr.sv \
        rtl/cdc_sync.sv \
        rtl/async_fifo.sv \
        tb/tb_async_fifo_day25.sv

    vvp "sim/day25_${name}.vvp" | tee "$log"

    grep -q "DAY 25 TEST PASSED" "$log"
    grep -q "FAILED CHECKS = 0" "$log"

    echo "$name,$dw,$aw,$depth,128,PASS" >> "$CSV"

    cp sim/day25_async_fifo.vcd "sim/day25_${name}.vcd"

    echo "[PASS] $name"
}

run_config C1 8 3
run_config C2 8 4
run_config C3 8 5
run_config C4 16 4
run_config C5 32 4

echo "======================================"
echo "ALL DAY 25 CONFIGURATIONS PASSED"
echo "======================================"

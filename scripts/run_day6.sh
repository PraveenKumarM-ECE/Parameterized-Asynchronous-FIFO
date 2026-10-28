#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

LOG="reports/day6_verification.log"

: > "$LOG"

run_test() {
    local width="$1"
    local addr="$2"
    local depth=$((1 << addr))
    local output="sim/day6_w${width}_d${depth}.vvp"

    echo "====================================" | tee -a "$LOG"
    echo "Testing WIDTH=$width DEPTH=$depth" | tee -a "$LOG"
    echo "====================================" | tee -a "$LOG"

    iverilog -g2012 \
        -s tb_fifo_day6 \
        -Ptb_fifo_day6.DW="$width" \
        -Ptb_fifo_day6.AW="$addr" \
        -o "$output" \
        rtl/sync_fifo.sv \
        tb/tb_fifo_day6.sv

    vvp "$output" | tee -a "$LOG"
}

run_test 8 2
run_test 8 3
run_test 8 4
run_test 16 4
run_test 32 5

echo "====================================" | tee -a "$LOG"
echo "ALL DAY 6 CONFIGURATIONS PASSED" | tee -a "$LOG"
echo "====================================" | tee -a "$LOG"

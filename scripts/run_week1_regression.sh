#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

LOG="reports/week1_regression.log"

: > "$LOG"

run_test() {
    local day="$1"
    local top="$2"
    local tb="$3"
    local output="sim/week1_day${day}.vvp"

    echo "====================================" | tee -a "$LOG"
    echo "RUNNING DAY $day" | tee -a "$LOG"
    echo "====================================" | tee -a "$LOG"

    iverilog -g2012 -s "$top" \
        -o "$output" \
        rtl/sync_fifo.sv \
        "tb/$tb"

    vvp "$output" | tee -a "$LOG"

    echo "DAY $day REGRESSION PASSED" | tee -a "$LOG"
}

run_test 2 tb_sync_fifo tb_sync_fifo.sv
run_test 3 tb_fifo_day3 tb_fifo_day3.sv
run_test 4 tb_fifo_day4 tb_fifo_day4.sv
run_test 5 tb_fifo_day5 tb_fifo_day5.sv

echo "====================================" | tee -a "$LOG"
echo "RUNNING DAY 6 PARAMETER TESTS" | tee -a "$LOG"
echo "====================================" | tee -a "$LOG"

./scripts/run_day6.sh | tee -a "$LOG"

run_test 7 tb_fifo_day7 tb_fifo_day7.sv

echo "====================================" | tee -a "$LOG"
echo "ALL WEEK 1 REGRESSION TESTS PASSED" | tee -a "$LOG"
echo "====================================" | tee -a "$LOG"

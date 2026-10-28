#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

REPORT="reports/day21_full_regression.log"
SUMMARY="reports/day21_summary.txt"

: > "$REPORT"
: > "$SUMMARY"

passed=0
failed=0

run_test() {
    local name="$1"
    local command="$2"
    local marker="$3"
    local logfile="reports/day21_${name}.log"

    echo "======================================" | tee -a "$REPORT"
    echo "RUNNING: $name" | tee -a "$REPORT"
    echo "======================================" | tee -a "$REPORT"

    if bash -c "$command" > "$logfile" 2>&1; then
        if grep -qF "$marker" "$logfile"; then
            echo "[PASS] $name" | tee -a "$REPORT" "$SUMMARY"
            passed=$((passed + 1))
        else
            echo "[FAIL] $name - PASS marker missing" \
                | tee -a "$REPORT" "$SUMMARY"
            tail -n 25 "$logfile" | tee -a "$REPORT"
            failed=$((failed + 1))
        fi
    else
        echo "[FAIL] $name - command failed" \
            | tee -a "$REPORT" "$SUMMARY"
        tail -n 25 "$logfile" | tee -a "$REPORT"
        failed=$((failed + 1))
    fi
}

echo "DAY 21 - FULL ASYNC FIFO REGRESSION" | tee -a "$REPORT"

# Day 13
run_test "day13_integration" \
"iverilog -g2012 -s tb_async_fifo_day13 \
-o sim/day21_day13.vvp \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv \
tb/tb_async_fifo_day13.sv && \
vvp sim/day21_day13.vvp" \
"DAY 13 TEST PASSED"

# Day 14
run_test "day14_cdc" \
"./scripts/run_day14.sh" \
"DAY 14 TEST PASSED"

# Day 15
run_test "day15_scoreboard" \
"./scripts/run_day15.sh" \
"DAY 15 TEST PASSED"

# Day 16
run_test "day16_boundaries" \
"./scripts/run_day16.sh" \
"DAY 16 TEST PASSED"

# Day 17
run_test "day17_clock_ratios" \
"./scripts/run_day17.sh" \
"ALL DAY 17 CLOCK TESTS PASSED"

# Day 18
run_test "day18_reset" \
"./scripts/run_day18.sh" \
"DAY 18 TEST PASSED"

# Day 19
run_test "day19_randomized" \
"./scripts/run_day19.sh" \
"ALL DAY 19 RANDOMIZED TESTS PASSED"

# Day 20
run_test "day20_assertions" \
"./scripts/run_day20.sh" \
"DAY 20 TEST PASSED"

# Verilator RTL lint
run_test "verilator_lint" \
"verilator --lint-only -Wall \
--top-module async_fifo \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv && \
echo LINT_PASSED" \
"LINT_PASSED"

# Yosys synthesis
run_test "yosys_synthesis" \
"yosys -Q -T -p ' \
read_verilog -sv \
rtl/async_fifo_memory.sv \
rtl/async_fifo_write_ptr.sv \
rtl/async_fifo_read_ptr.sv \
rtl/cdc_sync.sv \
rtl/async_fifo.sv
hierarchy -check -top async_fifo
proc
opt
memory
opt
techmap
opt
stat
check -assert
' && echo SYNTHESIS_PASSED" \
"SYNTHESIS_PASSED"

echo "======================================" | tee -a "$REPORT"
echo "DAY 21 REGRESSION SUMMARY" | tee -a "$REPORT"
echo "======================================" | tee -a "$REPORT"

echo "TOTAL TEST GROUPS = $((passed + failed))" | tee -a "$REPORT"
echo "PASSED GROUPS     = $passed" | tee -a "$REPORT"
echo "FAILED GROUPS     = $failed" | tee -a "$REPORT"

if [ "$failed" -eq 0 ] && [ "$passed" -eq 10 ]; then
    echo "DAY 21 FULL REGRESSION PASSED" | tee -a "$REPORT"
else
    echo "DAY 21 FULL REGRESSION FAILED" | tee -a "$REPORT"
    exit 1
fi

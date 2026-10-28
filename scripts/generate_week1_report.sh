#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

REPORT="reports/week1_summary.txt"

{
    echo "========================================"
    echo "ASYNCHRONOUS FIFO PROJECT"
    echo "WEEK 1 - SYNCHRONOUS FIFO VALIDATION"
    echo "========================================"
    echo
    echo "RTL MODULES:"
    echo "  rtl/fifo_memory.sv"
    echo "  rtl/sync_fifo.sv"
    echo
    echo "VERIFICATION:"
    grep -E \
        "DAY [2-7] TEST PASSED|ALL DAY 6 CONFIGURATIONS PASSED|ALL WEEK 1 REGRESSION TESTS PASSED" \
        reports/week1_regression.log
    echo
    echo "DAY 7 STRESS TEST:"
    grep -E \
        "TOTAL CYCLES|SUCCESSFUL WRITES|SUCCESSFUL READS|FULL HITS|EMPTY HITS|PASSED CHECKS|FAILED CHECKS" \
        reports/week1_regression.log | tail -n 7
    echo
    echo "SYNTHESIS:"
    echo "  reports/week1_synthesis.log"
    echo
    echo "STATUS: WEEK 1 COMPLETED"
    echo "========================================"
} > "$REPORT"

cat "$REPORT"

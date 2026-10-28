#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim reports

run_test() {
    local seed="$1"

    echo "======================================"
    echo "DAY 19 RANDOM SEED: $seed"
    echo "======================================"

    iverilog -g2012 \
    -s tb_async_fifo_day19 \
    -Ptb_async_fifo_day19.SEED="$seed" \
    -o "sim/day19_seed_${seed}.vvp" \
    rtl/async_fifo_memory.sv \
    rtl/async_fifo_write_ptr.sv \
    rtl/async_fifo_read_ptr.sv \
    rtl/cdc_sync.sv \
    rtl/async_fifo.sv \
    tb/tb_async_fifo_day19.sv

    vvp "sim/day19_seed_${seed}.vvp" \
    | tee "reports/day19_seed_${seed}.log"

    grep -q "DAY 19 TEST PASSED" \
    "reports/day19_seed_${seed}.log"
}

run_test 12345
run_test 24680
run_test 98765

echo "======================================"
echo "ALL DAY 19 RANDOMIZED TESTS PASSED"
echo "======================================"

#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p reports

run_synth() {
    local width="$1"
    local addr="$2"
    local depth=$((1 << addr))
    local log="reports/day6_synth_w${width}_d${depth}.log"

    echo "Synthesizing WIDTH=$width DEPTH=$depth"

    yosys -Q -T -p "
        read_verilog -sv rtl/sync_fifo.sv
        hierarchy -top sync_fifo -chparam DATA_WIDTH $width -chparam ADDR_WIDTH $addr
        proc
        opt
        memory
        opt
        stat
    " > "$log"

    echo "Saved: $log"
}

run_synth 8 2
run_synth 8 3
run_synth 8 4
run_synth 16 4
run_synth 32 5

echo "ALL DAY 6 SYNTHESIS RUNS COMPLETED"

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

CSV="reports/day23_resource_comparison.csv"

echo "configuration,data_width,addr_width,depth,storage_bits,total_cells" > "$CSV"

run_config() {
    local name="$1"
    local dw="$2"
    local aw="$3"

    local depth=$((1 << aw))
    local storage=$((dw * depth))

    local log="reports/day23_${name}_synthesis.log"
    local netlist="sim/day23_${name}_netlist.v"

    echo "======================================"
    echo "SYNTHESIZING $name"
    echo "DATA_WIDTH=$dw ADDR_WIDTH=$aw DEPTH=$depth"
    echo "======================================"

    yosys -Q -T -l "$log" -p "
        read_verilog -sv ${RTL_FILES[*]}
        chparam -set DATA_WIDTH $dw -set ADDR_WIDTH $aw async_fifo
        hierarchy -check -top async_fifo
        proc
        opt
        memory
        opt
        techmap
        opt
        check -assert
        stat
        write_verilog -noattr -noexpr $netlist
    " > /dev/null

    test -s "$netlist"

    local cells
    cells=$(awk '
        /^=== async_fifo ===/ {active=1; next}
        active && /Number of cells:/ {
            print $NF
            exit
        }
        active && /^[[:space:]]*[0-9]+[[:space:]]+cells/ {
            print $1
            exit
        }
        active && /^===/ {active=0}
    ' "$log")

    if [[ -z "$cells" ]]; then
        echo "ERROR: Could not extract cell count for $name"
        exit 1
    fi

    echo "$name,$dw,$aw,$depth,$storage,$cells" >> "$CSV"

    echo "TOTAL CELLS: $cells"
    echo "SYNTHESIS PASSED: $name"
}

run_config C1 8 3
run_config C2 8 4
run_config C3 8 5
run_config C4 16 4
run_config C5 32 4

echo "======================================"
echo "DAY 23 PARAMETER SCALING PASSED"
echo "======================================"

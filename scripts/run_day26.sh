#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p docs/diagrams reports

echo "======================================"
echo "DAY 26 - ARCHITECTURE DOCUMENTATION"
echo "======================================"

generate_diagram() {
    local name="$1"

    echo "Generating $name..."

    dot -Tpng \
        "docs/diagrams/${name}.dot" \
        -o "docs/diagrams/${name}.png"

    dot -Tsvg \
        "docs/diagrams/${name}.dot" \
        -o "docs/diagrams/${name}.svg"

    test -s "docs/diagrams/${name}.png"
    test -s "docs/diagrams/${name}.svg"

    echo "[PASS] $name"
}

generate_diagram async_fifo_architecture
generate_diagram gray_code_cdc
generate_diagram fifo_operation_flow

test -s docs/day26_architecture.md

{
    echo "DAY 26 ARCHITECTURE DOCUMENTATION"
    echo "================================"
    echo "Architecture diagrams: 3"
    echo "PNG diagrams: 3"
    echo "SVG diagrams: 3"
    echo "Technical documentation: 1"
    echo "Status: PASS"
} > reports/day26_documentation_summary.txt

echo "======================================"
echo "DAY 26 DOCUMENTATION PASSED"
echo "======================================"

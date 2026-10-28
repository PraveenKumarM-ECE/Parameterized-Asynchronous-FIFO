#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "======================================"
echo "DAY 27 - FINAL DOCUMENTATION CHECK"
echo "======================================"

python3 scripts/generate_day27.py

echo "[1/4] Checking documentation..."

test -s README.md
test -s docs/FINAL_PROJECT_REPORT.md
test -s reports/final_verification_summary.md
test -s reports/project_file_inventory.txt

echo "[PASS] Documentation"

echo "[2/4] Checking architecture diagrams..."

for name in async_fifo_architecture gray_code_cdc fifo_operation_flow
do
    test -s "docs/diagrams/${name}.png"
    test -s "docs/diagrams/${name}.svg"
done

echo "[PASS] Architecture diagrams"

echo "[3/4] Checking verification results..."

python3 - <<'PY'
import csv

with open("reports/day25_parameter_verification.csv") as f:
    rows = list(csv.DictReader(f))

assert len(rows) == 5
assert all(row["status"] == "PASS" for row in rows)
assert sum(int(row["transfers"]) for row in rows) == 640

print("[PASS] Five configurations, 640 transfers")
PY

echo "[4/4] Checking RTL files..."

for file in \
    async_fifo.sv \
    async_fifo_memory.sv \
    async_fifo_write_ptr.sv \
    async_fifo_read_ptr.sv \
    cdc_sync.sv
do
    test -s "rtl/$file"
done

echo "[PASS] RTL source files"

echo "======================================"
echo "DAY 27 DOCUMENTATION PASSED"
echo "======================================"

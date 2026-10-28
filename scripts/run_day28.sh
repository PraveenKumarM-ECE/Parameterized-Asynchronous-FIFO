#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p reports

echo "======================================"
echo "DAY 28 - FINAL PROJECT VALIDATION"
echo "======================================"

echo "[1/5] Checking RTL files..."

for file in \
    async_fifo.sv \
    async_fifo_memory.sv \
    async_fifo_write_ptr.sv \
    async_fifo_read_ptr.sv \
    cdc_sync.sv
do
    test -s "rtl/$file"
done

echo "[PASS] RTL files"

echo "[2/5] Running parameterized regression..."

./scripts/run_day25.sh > reports/day28_regression.log 2>&1

grep -q "ALL DAY 25 CONFIGURATIONS PASSED" \
    reports/day28_regression.log

echo "[PASS] Five parameter configurations"

echo "[3/5] Running CDC validation..."

./scripts/run_day24.sh > reports/day28_cdc.log 2>&1

grep -q "DAY 24 CDC DOCUMENTATION PASSED" \
    reports/day28_cdc.log

echo "[PASS] CDC structural checks and lint"

echo "[4/5] Checking synthesis evidence..."

test -s reports/day23_resource_comparison.csv

python3 - <<'PY'
import csv

with open("reports/day23_resource_comparison.csv") as f:
    rows = list(csv.DictReader(f))

assert len(rows) == 5

for row in rows:
    assert int(row["total_cells"]) > 0

print("[PASS] Five synthesis configurations")
PY

echo "[5/5] Running documentation verification..."

./scripts/run_day27.sh > reports/day28_docs.log 2>&1

grep -q "DAY 27 DOCUMENTATION PASSED" \
    reports/day28_docs.log

echo "[PASS] Final documentation"

echo "======================================"
echo "DAY 28 FINAL VALIDATION PASSED"
echo "======================================"
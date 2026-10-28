from pathlib import Path
import re
import sys

ROOT = Path(".")
RTL = ROOT / "rtl"
SDC = ROOT / "constraints/async_fifo.sdc"
DOC = ROOT / "docs/day24_cdc_architecture.md"
REPORT = ROOT / "reports/day24_cdc_validation.log"

results = []

def check(name, condition):
    status = "PASS" if condition else "FAIL"
    results.append((name, status))
    print(f"[{status}] {name}")

def read(path):
    if not path.is_file():
        return ""
    return path.read_text()

def no_comments(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    return re.sub(r"//.*", "", source)

top = no_comments(read(RTL / "async_fifo.sv"))
sync = no_comments(read(RTL / "cdc_sync.sv"))
write = no_comments(read(RTL / "async_fifo_write_ptr.sv"))
read_ptr = no_comments(read(RTL / "async_fifo_read_ptr.sv"))
sdc = no_comments(read(SDC))
doc = read(DOC)

print("=" * 45)
print("DAY 24 - CDC AND TIMING VALIDATION")
print("=" * 45)

check(
    "Write clock exists",
    bool(re.search(r"\bwr_clk\b", top))
)

check(
    "Read clock exists",
    bool(re.search(r"\brd_clk\b", top))
)

check(
    "Write pointer module instantiated",
    bool(re.search(r"\basync_fifo_write_ptr\b", top))
)

check(
    "Read pointer module instantiated",
    bool(re.search(r"\basync_fifo_read_ptr\b", top))
)

check(
    "Two CDC synchronizer instances",
    len(re.findall(r"\bcdc_sync\b", top)) >= 2
)

check(
    "Synchronizer has asynchronous reset",
    bool(re.search(
        r"always\s*@\s*\([^)]*\bposedge\b[^)]*"
        r"\bor\s+negedge\b",
        sync
    )) or bool(re.search(
        r"always_ff\s*@\s*\([^)]*\bposedge\b[^)]*"
        r"\bor\s+negedge\b",
        sync
    ))
)

check(
    "Synchronizer uses async_reg attribute",
    "async_reg" in read(RTL / "cdc_sync.sv").lower()
)

check(
    "Write Gray pointer exists",
    bool(re.search(r"\bwr_gray\b", write))
)

check(
    "Read Gray pointer exists",
    bool(re.search(r"\brd_gray\b", read_ptr))
)

check(
    "Write clock constraint",
    bool(re.search(
        r"create_clock\b[^\n]*-period\s+10(?:\.0+)?\b",
        sdc
    ))
)

check(
    "Read clock constraint",
    bool(re.search(
        r"create_clock\b[^\n]*-period\s+14(?:\.0+)?\b",
        sdc
    ))
)

check(
    "Asynchronous clock grouping",
    bool(re.search(r"set_clock_groups\s+-asynchronous", sdc))
)

check(
    "CDC documentation exists",
    len(doc.strip()) > 500
)

passed = sum(status == "PASS" for _, status in results)
failed = sum(status == "FAIL" for _, status in results)

summary = [
    "=" * 45,
    f"TOTAL CHECKS  = {len(results)}",
    f"PASSED CHECKS = {passed}",
    f"FAILED CHECKS = {failed}",
    "=" * 45,
]

for line in summary:
    print(line)

REPORT.parent.mkdir(parents=True, exist_ok=True)
REPORT.write_text(
    "\n".join(f"[{s}] {n}" for n, s in results)
    + "\n" + "\n".join(summary) + "\n"
)

if failed:
    print("DAY 24 VALIDATION FAILED")
    sys.exit(1)

print("DAY 24 VALIDATION PASSED")

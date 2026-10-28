from pathlib import Path
from datetime import datetime

reports = Path("reports")
summary = reports / "day21_summary.txt"
output = reports / "day21_verification_report.md"

if not summary.exists():
    raise SystemExit("Run Day 21 regression first.")

lines = summary.read_text().splitlines()

passed = [line for line in lines if line.startswith("[PASS]")]
failed = [line for line in lines if line.startswith("[FAIL]")]

status = "PASS" if len(passed) == 10 and not failed else "FAIL"

content = f"""# Day 21 - Asynchronous FIFO Verification Report

## Project
Design and Verification of a Parameterized Asynchronous FIFO
with Gray-Code-Based Clock Domain Crossing Using SystemVerilog

## Verification Date
{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## RTL Modules
- async_fifo.sv
- async_fifo_memory.sv
- async_fifo_write_ptr.sv
- async_fifo_read_ptr.sv
- cdc_sync.sv

## Verification Summary

| Metric | Result |
|---|---|
| Test groups | {len(passed) + len(failed)} |
| Passed | {len(passed)} |
| Failed | {len(failed)} |
| Overall status | {status} |

## Test Results

"""

for line in lines:
    content += f"- {line}\n"

content += """
## Verification Areas

- FIFO integration
- Clock domain crossing
- Data integrity scoreboard
- Full/empty boundary conditions
- Overflow and underflow protection
- Multiple independent clock ratios
- Reset and recovery
- Randomized traffic
- Gray-code pointer assertions
- Functional coverage
- RTL lint
- Synthesis checks

## Limitations

- RTL simulation does not model physical metastability.
- Static CDC sign-off and physical timing closure are not included.
- Independent one-sided reset recovery has not been verified.
- Coverage counters are simulation-based, not UCIS coverage reports.
"""

output.write_text(content)

print("Report generated:", output)
print("Overall status:", status)

if status != "PASS":
    raise SystemExit(1)

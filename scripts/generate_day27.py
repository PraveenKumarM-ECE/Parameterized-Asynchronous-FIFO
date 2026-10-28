
from pathlib import Path
import csv

ROOT = Path(".")
DOCS = ROOT / "docs"
REPORTS = ROOT / "reports"

DOCS.mkdir(exist_ok=True)
REPORTS.mkdir(exist_ok=True)


def read_csv(filename):
    with open(filename, newline="") as file:
        return list(csv.DictReader(file))


resources = read_csv("reports/day23_resource_comparison.csv")
verification = read_csv("reports/day25_parameter_verification.csv")

assert len(resources) == 5, "Expected 5 synthesis configurations"
assert len(verification) == 5, "Expected 5 verification configurations"
assert all(row["status"] == "PASS" for row in verification)

total_transfers = sum(int(row["transfers"]) for row in verification)


def make_table(rows, columns):
    header = "| " + " | ".join(columns) + " |"
    separator = "| " + " | ".join(["---"] * len(columns)) + " |"
    body = []

    for row in rows:
        body.append(
            "| " + " | ".join(str(row[col]) for col in columns) + " |"
        )

    return "\n".join([header, separator] + body)


verification_table = make_table(
    verification,
    [
        "configuration",
        "data_width",
        "addr_width",
        "depth",
        "transfers",
        "status",
    ],
)

resource_table = make_table(
    resources,
    [
        "configuration",
        "data_width",
        "addr_width",
        "depth",
        "storage_bits",
        "total_cells",
    ],
)


readme = f"""
# Parameterized Asynchronous FIFO Using SystemVerilog

## Project Overview

This project implements a parameterized asynchronous FIFO
(First-In, First-Out) buffer using SystemVerilog.

It transfers data between two independent clock domains
using Gray-code pointers and two-flip-flop synchronizers.

## Features

- Independent write and read clocks
- Configurable data width and FIFO depth
- Binary and Gray-code pointers
- Two-stage CDC synchronizers
- Full and empty flag generation
- Overflow and underflow prevention
- Pointer wraparound
- Reset support
- Self-checking SystemVerilog testbenches
- Randomized scoreboard verification
- Parameterized configuration testing

## Architecture

![FIFO Architecture](docs/diagrams/async_fifo_architecture.png)

![Gray-Code CDC](docs/diagrams/gray_code_cdc.png)

![FIFO Operation](docs/diagrams/fifo_operation_flow.png)

## RTL Modules

| Module | Description |
|---|---|
| async_fifo.sv | Top-level FIFO |
| async_fifo_memory.sv | FIFO memory |
| async_fifo_write_ptr.sv | Write pointer and full detection |
| async_fifo_read_ptr.sv | Read pointer and empty detection |
| cdc_sync.sv | Two-stage synchronizer |
| bin_to_gray.sv | Binary-to-Gray converter |
| gray_to_bin.sv | Gray-to-binary converter |
| gray_pointer_counter.sv | Gray pointer counter |

## Tools

- SystemVerilog
- Icarus Verilog
- Verilator
- Yosys
- GTKWave
- Graphviz
- Python
- WSL Ubuntu

## Parameterized Verification Results

{verification_table}

Total verified transfers: {total_transfers}

## Synthesis Results

{resource_table}

Generic Yosys cell counts do not represent physical ASIC area.

## Running Verification

Run the Day 25 regression using:

    ./scripts/run_day25.sh

## Documentation

- [CDC Architecture](docs/day24_cdc_architecture.md)
- [Technical Architecture](docs/day26_architecture.md)
- [Final Project Report](docs/FINAL_PROJECT_REPORT.md)
- [Verification Summary](reports/final_verification_summary.md)

## Project Status

RTL design, functional verification, lint,
generic synthesis and documentation completed.
"""


report = f"""
# Final Project Report

## Project Title

Design and Verification of a Parameterized Asynchronous FIFO
with Gray-Code-Based Clock Domain Crossing Using SystemVerilog

## 1. Abstract

This project implements a parameterized asynchronous FIFO
for reliable data buffering between independent clock domains.

Gray-code pointers and two-stage synchronizers are used
to reduce clock-domain crossing risks.

## 2. Objectives

- Design parameterized FIFO memory.
- Implement binary and Gray-code pointers.
- Develop two-stage CDC synchronizers.
- Implement full and empty detection.
- Prevent overflow and underflow.
- Verify multiple clock frequencies.
- Perform randomized scoreboard verification.
- Test different FIFO widths and depths.
- Perform lint and generic synthesis.

## 3. Architecture

The FIFO contains five main blocks:

1. FIFO memory
2. Write pointer and full detection
3. Read pointer and empty detection
4. Write-to-read synchronizer
5. Read-to-write synchronizer

## 4. Working Principle

Write operations occur in the write clock domain.

Read operations occur in the read clock domain.

Binary pointers maintain FIFO memory addresses.

Gray-code pointers cross clock domains through
two-stage synchronizers.

The full flag prevents overflow.

The empty flag prevents underflow.

## 5. Parameterization

FIFO depth = 2^ADDR_WIDTH

Storage bits = DATA_WIDTH * FIFO depth

## 6. Verification Methodology

- Directed functional tests
- Reset verification
- Full and empty testing
- Overflow and underflow testing
- Pointer wraparound testing
- Independent clock-frequency testing
- Randomized scoreboard testing
- Assertions and coverage
- Parameterized regression
- Verilator lint
- Yosys synthesis

## 7. Parameterized Verification Results

{verification_table}

Total verified transfers: {total_transfers}

All five configurations passed.

## 8. Synthesis Results

{resource_table}

## 9. Clock Domain Crossing

Gray-code pointers are synchronized between
independent clock domains using two-flop synchronizers.

Gray coding reduces incoherent pointer sampling
but does not eliminate metastability.

## 10. Limitations

RTL simulation does not model physical metastability.

Physical CDC sign-off and technology-specific
static timing analysis have not been performed.

Generic Yosys cell counts are not ASIC area.

## 11. Applications

- Communication interfaces
- Multi-clock digital systems
- Data acquisition systems
- FPGA and ASIC subsystems
- Processor-to-peripheral buffering

## 12. Conclusion

The parameterized asynchronous FIFO was successfully
implemented and functionally verified across five
width and depth configurations.

The project demonstrates SystemVerilog RTL design,
CDC techniques, functional verification and synthesis.
"""


summary = f"""
# Final Verification Summary

## Parameterized Regression

{verification_table}

Total verified transfers: {total_transfers}

Failed configurations: 0

## Synthesis Results

{resource_table}

## Completed Verification Activities

- FIFO memory verification
- Write and read pointer verification
- Gray-code conversion
- CDC synchronizer verification
- FIFO integration
- Reset and boundary testing
- Clock-frequency variation testing
- Randomized scoreboard testing
- Assertions and coverage
- Parameterized regression
- Verilator lint
- Yosys generic synthesis
- CDC documentation

## Verification Limitations

Physical CDC sign-off and technology-specific
timing closure were not performed.
"""


(ROOT / "README.md").write_text(readme.strip() + "\n")
(DOCS / "FINAL_PROJECT_REPORT.md").write_text(report.strip() + "\n")
(REPORTS / "final_verification_summary.md").write_text(
    summary.strip() + "\n"
)

files = sorted(
    str(path)
    for path in ROOT.rglob("*")
    if path.is_file() and ".git" not in path.parts
)

(REPORTS / "project_file_inventory.txt").write_text(
    "\n".join(files) + "\n"
)

print("======================================")
print("DAY 27 DOCUMENTATION GENERATED")
print("Verified configurations:", len(verification))
print("Verified transfers:", total_transfers)
print("======================================")

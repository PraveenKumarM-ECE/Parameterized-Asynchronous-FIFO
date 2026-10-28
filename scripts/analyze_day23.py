import csv
from pathlib import Path

source = Path("reports/day23_resource_comparison.csv")
output = Path("reports/day23_resource_analysis.md")

with source.open() as f:
    rows = list(csv.DictReader(f))

if len(rows) != 5:
    raise SystemExit("ERROR: Expected 5 configurations.")

for row in rows:
    for key in ("data_width", "addr_width", "depth",
                "storage_bits", "total_cells"):
        row[key] = int(row[key])

lines = [
    "# Day 23 - Asynchronous FIFO Resource Analysis",
    "",
    "## Synthesis Results",
    "",
    "| Config | Data Width | Depth | Storage Bits | Cells |",
    "|---|---:|---:|---:|---:|",
]

for r in rows:
    lines.append(
        f"| {r['configuration']} | {r['data_width']} | "
        f"{r['depth']} | {r['storage_bits']} | "
        f"{r['total_cells']} |"
    )

base = rows[1]

lines += [
    "",
    "## Comparison Against C2",
    "",
    "| Config | Cell Difference | Percentage Change |",
    "|---|---:|---:|",
]

for r in rows:
    diff = r["total_cells"] - base["total_cells"]
    pct = 100 * diff / base["total_cells"]

    lines.append(
        f"| {r['configuration']} | {diff:+d} | {pct:+.2f}% |"
    )

lines += [
    "",
    "## Observations",
    "",
    "- Increasing data width increases storage capacity.",
    "- Increasing address width increases FIFO depth exponentially.",
    "- Resource utilization depends on width, depth, and control logic.",
    "- Generic Yosys cell counts are not physical ASIC area.",
    "",
    "## Conclusion",
    "",
    "Five FIFO configurations were successfully synthesized.",
]

output.write_text("\n".join(lines) + "\n")

print("DAY 23 RESOURCE ANALYSIS PASSED")
print("Generated:", output)

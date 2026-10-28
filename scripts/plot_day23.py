import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")

import matplotlib.pyplot as plt

source = Path("reports/day23_resource_comparison.csv")
output = Path("reports/day23_resource_comparison.png")

with source.open() as f:
    rows = list(csv.DictReader(f))

labels = [
    f"{r['configuration']}\n"
    f"{r['data_width']}b x {r['depth']}"
    for r in rows
]

cells = [int(r["total_cells"]) for r in rows]

fig, ax = plt.subplots(figsize=(9, 5))

bars = ax.bar(labels, cells)

ax.set_title("Asynchronous FIFO Resource Utilization")
ax.set_xlabel("FIFO Configuration")
ax.set_ylabel("Yosys Generic Cell Count")
ax.grid(axis="y", alpha=0.25)

for bar, value in zip(bars, cells):
    ax.text(
        bar.get_x() + bar.get_width() / 2,
        bar.get_height(),
        str(value),
        ha="center",
        va="bottom"
    )

fig.tight_layout()
fig.savefig(output, dpi=180)

print("DAY 23 CHART GENERATED")
print("Generated:", output)

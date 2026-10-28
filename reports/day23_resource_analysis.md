# Day 23 - Asynchronous FIFO Resource Analysis

## Synthesis Results

| Config | Data Width | Depth | Storage Bits | Cells |
|---|---:|---:|---:|---:|
| C1 | 8 | 8 | 64 | 7 |
| C2 | 8 | 16 | 128 | 7 |
| C3 | 8 | 32 | 256 | 7 |
| C4 | 16 | 16 | 256 | 7 |
| C5 | 32 | 16 | 512 | 7 |

## Comparison Against C2

| Config | Cell Difference | Percentage Change |
|---|---:|---:|
| C1 | +0 | +0.00% |
| C2 | +0 | +0.00% |
| C3 | +0 | +0.00% |
| C4 | +0 | +0.00% |
| C5 | +0 | +0.00% |

## Observations

- Increasing data width increases storage capacity.
- Increasing address width increases FIFO depth exponentially.
- Resource utilization depends on width, depth, and control logic.
- Generic Yosys cell counts are not physical ASIC area.

## Conclusion

Five FIFO configurations were successfully synthesized.

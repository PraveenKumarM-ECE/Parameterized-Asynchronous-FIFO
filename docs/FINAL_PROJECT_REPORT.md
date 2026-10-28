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

| configuration | data_width | addr_width | depth | transfers | status |
| --- | --- | --- | --- | --- | --- |
| C1 | 8 | 3 | 8 | 128 | PASS |
| C2 | 8 | 4 | 16 | 128 | PASS |
| C3 | 8 | 5 | 32 | 128 | PASS |
| C4 | 16 | 4 | 16 | 128 | PASS |
| C5 | 32 | 4 | 16 | 128 | PASS |

Total verified transfers: 640

All five configurations passed.

## 8. Synthesis Results

| configuration | data_width | addr_width | depth | storage_bits | total_cells |
| --- | --- | --- | --- | --- | --- |
| C1 | 8 | 3 | 8 | 64 | 7 |
| C2 | 8 | 4 | 16 | 128 | 7 |
| C3 | 8 | 5 | 32 | 256 | 7 |
| C4 | 16 | 4 | 16 | 256 | 7 |
| C5 | 32 | 4 | 16 | 512 | 7 |

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

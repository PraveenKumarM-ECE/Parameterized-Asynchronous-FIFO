# Day 24 — Asynchronous FIFO CDC Architecture

## 1. Project

Design and Verification of a Parameterized Asynchronous FIFO
with Gray-Code-Based Clock Domain Crossing Using SystemVerilog.

## 2. Clock Domains

The FIFO operates using two independent clock domains:

- Write domain: wr_clk
- Read domain: rd_clk

The clocks may have different frequencies and phases.

## 3. CDC Architecture

Write domain:

1. Accept write requests when full = 0.
2. Write data into FIFO memory.
3. Increment the binary write pointer.
4. Convert the write pointer to Gray code.
5. Synchronize the Gray pointer into the read domain.

Read domain:

1. Accept read requests when empty = 0.
2. Read data from FIFO memory.
3. Increment the binary read pointer.
4. Convert the read pointer to Gray code.
5. Synchronize the Gray pointer into the write domain.

## 4. Gray-Code Pointer Crossing

Binary pointers may change multiple bits during one increment.

Gray-code pointers change only one bit per increment.

This reduces the risk of capturing an incoherent
multi-bit pointer during clock-domain crossing.

Gray coding does not eliminate metastability.

## 5. Two-Flip-Flop Synchronizers

The FIFO uses two-stage synchronizers for the
cross-domain Gray-code pointer signals.

Write Gray pointer:
wr_gray -> read-domain synchronizer -> wr_gray_sync

Read Gray pointer:
rd_gray -> write-domain synchronizer -> rd_gray_sync

The first stage may become metastable.
The second stage reduces the probability that
metastability propagates into destination logic.

## 6. Full Detection

Full detection occurs in the write clock domain.

The next write Gray pointer is compared with
the synchronized read Gray pointer after
inverting its two most significant bits.

## 7. Empty Detection

Empty detection occurs in the read clock domain.

The next read Gray pointer is compared with
the synchronized write Gray pointer.

## 8. Timing Constraints

Write clock period: 10 ns.
Read clock period: 14 ns.

The clocks are asynchronous.

The SDC file defines independent clock groups.

The asynchronous clock-group exception must not
be treated as proof that the CDC implementation is safe.

## 9. Important CDC Requirements

- Preserve the two-flop synchronizer structures.
- Keep the first and second synchronizer stages close.
- Do not introduce combinational logic between stages.
- Apply appropriate Gray-bus skew or maximum-delay
  constraints during physical implementation.
- Ensure source pointer signals settle within the
  required CDC timing window.
- Use a coordinated reset protocol.
- Perform CDC structural analysis before tape-out.

## 10. Verification Status

Completed verification includes:

- FIFO data integrity
- Full and empty detection
- Overflow and underflow protection
- Multiple clock frequency ratios
- Reset and recovery
- Randomized scoreboard testing
- Gray-code pointer assertions
- Functional coverage
- RTL lint
- Generic synthesis

## 11. Limitations

RTL simulation does not model physical metastability.

The current SDC is an example constraint file.
It has not been validated in a technology-specific
static timing analysis or place-and-route flow.

Independent one-sided reset recovery is not verified.

The current FIFO memory uses asynchronous read logic.
Actual RAM inference and read-during-write behavior
depend on the target implementation technology.

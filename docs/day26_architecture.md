# Day 26 — Asynchronous FIFO Architecture

## 1. Project Title

Design and Verification of a Parameterized Asynchronous FIFO
with Gray-Code-Based Clock Domain Crossing Using SystemVerilog.

## 2. Project Objective

Design a configurable FIFO buffer capable of transferring
data between two independent clock domains.

The FIFO must maintain data ordering and prevent overflow
and underflow while supporting multiple widths and depths.

## 3. Main Components

### FIFO Memory

Stores DATA_WIDTH-bit words in a memory array.

Memory depth = 2^ADDR_WIDTH.

### Write Pointer

Maintains the current write address.

Generates a binary pointer and its Gray-code equivalent.

Detects the full condition using the synchronized
read pointer.

### Read Pointer

Maintains the current read address.

Generates a binary pointer and its Gray-code equivalent.

Detects the empty condition using the synchronized
write pointer.

### Clock Domain Synchronizer

Uses two flip-flop stages to transfer Gray-code
pointer information between independent clock domains.

### Top-Level Integration

Connects memory, write pointer, read pointer,
and synchronizers into one asynchronous FIFO.

## 4. Parameterization

DATA_WIDTH controls the number of bits per word.

ADDR_WIDTH controls the number of memory addresses.

FIFO_DEPTH = 2^ADDR_WIDTH.

Examples:

| DATA_WIDTH | ADDR_WIDTH | DEPTH |
|---|---|---|
| 8 | 3 | 8 |
| 8 | 4 | 16 |
| 8 | 5 | 32 |
| 16 | 4 | 16 |
| 32 | 4 | 16 |

## 5. Write Operation

1. Receive wr_en and wr_data.
2. Check full.
3. If not full, store the data at the write address.
4. Increment the binary write pointer.
5. Convert the pointer to Gray code.
6. Update full detection.

## 6. Read Operation

1. Receive rd_en.
2. Check empty.
3. If not empty, consume data at the read address.
4. Increment the binary read pointer.
5. Convert the pointer to Gray code.
6. Update empty detection.

The current implementation provides asynchronous
combinational memory read data.

## 7. Gray-Code CDC

Binary pointers can change multiple bits at once.

Gray-code pointers change only one bit per increment.

The Gray pointers are synchronized using two flip-flop
stages before being used in the opposite clock domain.

Physical Gray-bus timing constraints are still required
for reliable hardware implementation.

## 8. Verification

Completed tests include:

- Reset behavior
- FIFO full and empty conditions
- Overflow and underflow protection
- Pointer wraparound
- Independent clock frequencies
- Randomized data transfers
- Scoreboard-based data integrity
- Assertions and coverage
- Parameterized configurations
- Verilator lint
- Yosys synthesis

## 9. Day 25 Results

Five configurations passed.

Total verified transfers: 640.

Total verification checks: 680.

Failed checks: 0.

## 10. Limitations

RTL simulation does not model physical metastability.

Generic Yosys synthesis does not establish physical
area, power, or timing closure.

The example SDC has not undergone technology-specific
static timing analysis.

CDC physical implementation and independent reset
recovery require additional sign-off verification.

## 11. Diagrams

- async_fifo_architecture.png
- gray_code_cdc.png
- fifo_operation_flow.png

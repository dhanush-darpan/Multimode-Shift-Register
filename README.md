# Multi-Mode Shift Register

A parameterizable 4-bit **Multi-Mode Shift Register** implemented in Verilog, supporting four classical shift-register operating modes — SISO, SIPO, PIPO, and PISO — selected via a 2-bit control signal.

---

## Table of Contents

- [Block Diagram](#block-diagram)
- [Port Description](#port-description)
- [Operating Modes](#operating-modes)
- [Timing & Reset Behavior](#timing--reset-behavior)
- [Design Notes & Subtleties](#design-notes--subtleties)
- [File Structure](#file-structure)
- [Simulation](#simulation)
- [Waveform Walkthrough](#waveform-walkthrough)
- [Known Limitations](#known-limitations)

---

## Block Diagram

```
              ┌──────────────────────────────────┐
    clk  ────►│                                  │
    rst  ────►│          MMSR (4-bit)            │──► so
    sel[1:0]─►│                                  │
    load ────►│     mem[3:0]  (internal reg)     │──► po[3:0]
    si   ────►│                                  │
    pi[3:0]──►│                                  │
              └──────────────────────────────────┘
```

---

## Port Description

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | Clock — all operations trigger on **posedge** |
| `rst` | Input | 1 | Asynchronous reset, **active-low** — resets `mem` to `0` on negedge |
| `sel[1:0]` | Input | 2 | Mode select (see Operating Modes) |
| `load` | Input | 1 | Load enable for PISO mode |
| `si` | Input | 1 | Serial input (used in SISO and SIPO) |
| `pi[3:0]` | Input | 4 | Parallel input (used in PIPO and PISO) |
| `so` | Output (reg) | 1 | Serial output (used in SISO and PISO) |
| `po[3:0]` | Output (reg) | 4 | Parallel output (used in SIPO and PIPO) |

---

## Operating Modes

| `sel` | Mode | Description |
|-------|------|-------------|
| `2'b00` | **SISO** — Serial In, Serial Out | Right-shifts `mem`; `si` enters at MSB (`mem[3]`); serial output `so` reflects `mem[0]` from the **previous** cycle |
| `2'b01` | **SIPO** — Serial In, Parallel Out | Right-shifts `mem`; `si` enters at MSB; parallel output `po` reflects `mem` from the **previous** cycle |
| `2'b10` | **PIPO** — Parallel In, Parallel Out | Latches `pi` into `mem`; `po` reflects `mem` from the **previous** cycle (1-cycle latency) |
| `2'b11` | **PISO** — Parallel In, Serial Out | If `load=1`: latches `pi` into `mem`. If `load=0`: right-shifts `mem` by 1; `so` reflects `mem[0]` from the **previous** cycle |

### Shift Direction

All shift operations are **right shifts**:

```
mem <= { si, mem[3:1] }   // si → mem[3], mem[3]→mem[2], mem[2]→mem[1], mem[1]→mem[0] (dropped)
```

The serial output (`so`) captures `mem[0]` **before** the shift register updates, due to non-blocking assignment semantics — there is a 1-clock-cycle output latency.

---

## Timing & Reset Behavior

- **Clock edge:** All state updates occur on the **rising edge** of `clk`.
- **Reset:** Asynchronous, **active-low**. Asserted when `rst = 0` (negedge triggers the always block). Only `mem` is reset to `4'b0000`. The output registers `so` and `po` are **not** explicitly reset and will hold their last driven values.
- **Output latency:** Because `so` and `po` are assigned from `mem` in the same always block using non-blocking assignments (`<=`), they reflect the **state of `mem` before the current clock edge** — i.e., there is always a 1-cycle output delay relative to the internal state.

### Reset Connectivity Caution

> ⚠️ The `rst` signal is labeled "active-low" and used as `if(!rst)` in the sensitivity list triggered by `negedge rst`. This is consistent and correct, but unusual — ensure your testbench asserts `rst=0` to reset and `rst=1` to release.

---

## Design Notes & Subtleties

### 1. Output registers are not reset
`so` and `po` are declared as `reg` but are only driven inside the mode `case` branches. After reset, they retain whatever value they held previously (synthesis tools may or may not infer reset logic here depending on target).

### 2. PIPO has a 1-cycle output lag
In PIPO mode:
```verilog
mem <= pi;   // mem gets pi AFTER the clock edge
po  <= mem;  // po gets the OLD mem value at this clock edge
```
So `po` shows the value of `pi` from the **previous** clock cycle, not the current one. This is a classic registered-output behavior — not a bug, but an important functional characteristic.

### 3. SISO and SIPO share the same shift logic
The only difference between SISO and SIPO is which output port is driven (`so` vs `po`). The internal `mem` update is identical.

### 4. PISO load vs shift
In PISO mode (`sel=2'b11`):
- `load=1`: Parallel data is latched (`mem <= pi`). No serial output is driven in this cycle.
- `load=0`: `mem` is right-shifted by 1 bit (`mem <= mem >> 1`) and `so <= mem[0]` captures the LSB before the shift.

### 5. `default` case
The `default` branch in the `case` statement resets `mem` to zero. `so` and `po` are not touched and retain their last values.

---

## File Structure

```
mmsr/
├── mmsr.v          # DUT: Multi-Mode Shift Register
├── usr_tb.v        # Testbench
├── dump.vcd        # Generated waveform (after simulation)
└── README.md
```

---

## Simulation

### Requirements

Any of the following simulators:

- [Icarus Verilog](http://iverilog.icarus.com/) (free, open-source)
- ModelSim / QuestaSim
- Xilinx Vivado / Intel Quartus simulator

### Running with Icarus Verilog

```bash
# Compile
iverilog -o mmsr_sim mmsr.v usr_tb.v

# Run simulation (generates dump.vcd and $monitor output)
vvp mmsr_sim

# View waveform
gtkwave dump.vcd
```

### Monitor Output Format

```
sim time=<t> | sel=<xx>, load=<x>, si=<x>, pi=<xxxx>, so=<x>, po=<xxxx>
```

---

## Waveform Walkthrough

The testbench exercises all four modes sequentially. The clock period is **10 ns** (toggling every 5 ns). Reset is deasserted at **t=5 ns**.

### Phase 1 — SISO (`sel=2'b00`, t=5 ns onward)

Serial bits `1,0,1,0,1,1` are shifted in via `si`. Each bit enters at `mem[3]` on every rising clock edge. `so` outputs `mem[0]` from the previous cycle, so the serial output stream is delayed by the register depth.

### Phase 2 — SIPO (`sel=2'b01`)

Serial input continues; `po` shows the accumulated contents of `mem` (from the previous cycle) on every clock edge. After 4 shifts, `po` holds the last 4 bits shifted in, in right-shifted order.

### Phase 3 — PIPO (`sel=2'b10`)

Parallel inputs `4'b1000`, `4'b0100`, `4'b0010`, `4'b0001` are applied. `po` outputs the **previously loaded** value on each clock edge (1-cycle lag).

### Phase 4 — PISO (`sel=2'b11`)

Four parallel words are loaded and then serially shifted out:
- `load=1` → `pi` is latched into `mem`
- `load=0` for 4 cycles → bits shift out LSB-first via `so`

---

## Known Limitations

| Limitation | Detail |
|------------|--------|
| Fixed 4-bit width | `mem`, `pi`, and `po` are hardcoded to 4 bits. No parameter for width. |
| `so`/`po` not reset | Output registers hold stale values after reset until re-driven by active mode logic. |
| No simultaneous SI+PO or SI+SO routing | Each mode drives only one output port; the other retains its last value. |
| Shift direction fixed | Only right-shift is supported; no left-shift or bidirectional mode. |
| Single `load` in PISO | There is no auto-cycling: the user must manually deassert `load` and count shift cycles to fully serialize the loaded word. |

---

## License

This project is provided for educational and verification purposes.

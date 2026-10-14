# mult4-rtl-to-gds

4-bit unsigned array multiplier in Verilog, taken from RTL to GDSII on SkyWater
SKY130 using open-source tools (Yosys, OpenSTA, LibreLane).
ECE463 Digital VLSI Design assignment.

## Team

| Name | Roll number |
|---|---|
| Monishram Selvaraj | 2024102076 |
| Neel Rajesh | 2024102007 |

## Environment

IIC-OSIC-TOOLS Docker image, PDK `sky130A`, standard cell library
`sky130_fd_sc_hd`. The designs directory `~/eda/designs` on the host is mounted
at `/foss/designs` inside the container.

```
eda-start      # start container, open browser desktop at http://localhost
eda-stop       # stop container
```

## Commands run, in order

### Part A — RTL and verification

```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

Result:

```
PASS: 256 vectors checked, 0 errors
```

Error-injection check (task 6) — `sum` in `full_adder.v` temporarily changed
from `a ^ b ^ cin` to `a ^ b`, then reverted:

```
MISMATCH: a=3 b=3 expected=9 (00001001) got=5 (00000101) at time 1066000
MISMATCH: a=3 b=6 expected=18 (00010010) got=10 (00001010) at time 1126000
MISMATCH: a=3 b=7 expected=21 (00010101) got=9 (00001001) at time 1146000
FAIL: 256 vectors checked, 95 errors
```

Worked example (task 5): A = last digit of roll number 2024102076 (6) + 5 = 11,
B = 7. Roll number used: Monishram Selvaraj, 2024102076.

### Part B — Synthesis

```
yosys -c synth/synth.tcl
```

Gate-level simulation of the synthesized netlist (same testbench as Part A):

```
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v \
  synth/mult_array_netlist.v
vvp gls
```

Result:

```
PASS: 256 vectors checked, 0 errors
```

#### Part B results

| Metric | Value |
|---|---|
| Total number of cells | 67 |
| Number of flip-flops | 16 |
| Total cell area | 746.9664 um^2 |
| Flip-flop area | 400.384 um^2 (16 x 25.024) |
| Flip-flop area (% of total) | 53.60% |
| 3 most-used cell types | `dfrtp_1` (16), `nand2_1` (12), `xnor2_1` (7) |
| Netlist simulation result | PASS: 256 vectors checked, 0 errors |

Logic cells (total minus flip-flops): 67 - 16 = 51.

Note: the first gate-level run failed with every result lagging one vector
behind. The cause was in the testbench, not the design: `-DUNIT_DELAY=#1`
gives each standard cell a one-unit delay, so sampling `p` at `#1` after the
clock edge raced with the flip-flop output. Sampling at `@(negedge clk)`
instead puts it clear of the edge, and both RTL and gate-level now pass.

### Part C — Static timing analysis

```
```

### Part D — Physical design

LibreLane attempts (record every run, including failed ones):

| Attempt | CLOCK_PERIOD (ns) | Setup slack | DRC | LVS | Result |
|---|---|---|---|---|---|
| 1 | | | | | |

```
```

## Repository layout

```
rtl/     full_adder.v, mult_array.v
tb/      tb_mult.v
synth/   synth.tcl + generated netlist and stat report
sta/     sta.tcl + generated timing report
pnr/     config.json + metrics.json and GDS copied from the final run
report/  report.pdf
```

## License

MIT — see [LICENSE](LICENSE).

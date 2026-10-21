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
sta sta/sta.tcl
```

Run first with `CLK_PERIOD 10.0`, then again with `CLK_PERIOD` set to T_min to
confirm the slack is close to zero.

#### Part C results

| Metric | Value |
|---|---|
| Worst slack at T = 10 ns | 7.396 ns |
| T_min | 2.604 ns (10 - 7.396) |
| F_max | 384.0 MHz (1000 / 2.604) |
| Slack at T = T_min (2.60 ns) | -0.00 ns |
| Critical path start point | `_106_` (sky130_fd_sc_hd__dfrtp_1 flip-flop) |
| Critical path end point | `_100_` (sky130_fd_sc_hd__dfrtp_1 flip-flop) |
| Number of cells on the critical path | 8 combinational (10 including both flip-flops) |
| Latency = 2 x T_min | 5.208 ns |
| Throughput | 384.0 million results per second |

Cells on the critical path, in order:

```
_106_/Q    dfrtp_1     0.388   launching flip-flop
_043_/X    and2_0      0.180
_056_/X    or3_1       0.391
_058_/Y    a32oi_1     0.250
_072_/X    o21ba_1     0.198
_073_/Y    xnor2_1     0.147
_082_/X    maj3_1      0.385
_084_/X    maj3_1      0.358
_088_/X    xnor3_1     0.175
_100_/D    dfrtp_1     0.000   capturing flip-flop
                       -----
         arrival time  2.471 ns
```

Of the 8 combinational cells, 4 are adder arithmetic: two `maj3_1` (full-adder
carry, the majority function), one `xnor3_1` (full-adder sum) and one `xnor2_1`
(half-adder sum). `and2_0` is a partial-product gate; `or3_1`, `a32oi_1` and
`o21ba_1` are merged carry logic.

### Part D — Physical design

`CLOCK_PERIOD` is derived from Part C:

```
1.2 x T_min = 1.2 x 2.604 = 3.125 ns  ->  rounded up to the next 0.5 ns  =  3.5 ns
```

```
cd pnr
librelane config.json
```

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

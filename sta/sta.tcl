# ---------------------------------------------------------------------------
# sta.tcl
#
# OpenSTA static timing analysis for mult_array (assignment section 8).
# Run from the repository root with:  sta sta/sta.tcl
#
# Checks every register-to-register path against the clock period, with no
# simulation. Typical corner (tt_025C_1v80) only.
#
# HOW TO USE THIS SCRIPT
#   1. Run it as-is, with CLK_PERIOD = 10.0. Note the worst slack (WNS).
#   2. T_min = 10.0 - WNS        F_max = 1000 / T_min   (MHz, T_min in ns)
#   3. Set CLK_PERIOD below to T_min (rounded to 0.01 ns) and run again.
#      The slack should now be close to 0, which confirms the arithmetic.
# ---------------------------------------------------------------------------

# Clock period in ns. Start at 10.0, then re-run at T_min (see above).
set CLK_PERIOD 10.0

# Liberty timing library (typical corner), section 4.2
set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 1. Read the cell timing library
read_liberty $lib

# 2. Read and link the netlist
read_verilog synth/mult_array_netlist.v
link_design mult_array

# 3. Define the clock
create_clock -name clk -period $CLK_PERIOD [get_ports clk]

# 4. Input arrival time (every input except the clock)
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# 5. Output required time
set_output_delay 1.0 -clock clk [all_outputs]

# 6. Print the worst setup slack
puts "=============================================="
puts "Clock period T = $CLK_PERIOD ns"
puts "=============================================="
report_worst_slack -max

# 7. Save the critical path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt

# Convenience: also show the critical path on screen
report_checks -path_delay max -digits 3

// ---------------------------------------------------------------------------
// tb_mult.v
//
// Exhaustive self-checking testbench for mult_array (assignment section 6).
//
// Requirements implemented:
//   - 10 ns clock period, rst_n held low for the first 2 cycles
//   - all 256 input combinations (a = 0..15, b = 0..15)
//   - waits for the 2-cycle latency before comparing p with a * b
//     (the * operator is allowed in the testbench only)
//   - prints a line for every mismatch
//   - prints exactly one summary line:
//       PASS: 256 vectors checked, 0 errors
//     or FAIL: ... with the error count
//   - writes the waveform file mult.vcd
//
// This same testbench is reused unchanged for the gate-level simulation of the
// synthesized netlist in Part B.
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_mult;

    // Clock period in ns
    localparam integer CLK_PERIOD = 10;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;

    integer    ia;
    integer    ib;
    integer    errors;
    integer    checked;
    reg  [7:0] expected;

    // -----------------------------------------------------------------------
    // Device under test
    // -----------------------------------------------------------------------
    mult_array dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // -----------------------------------------------------------------------
    // Clock: 10 ns period
    // -----------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);
    end

    // -----------------------------------------------------------------------
    // Stimulus and checking
    // -----------------------------------------------------------------------
    initial begin
        errors  = 0;
        checked = 0;
        a       = 4'd0;
        b       = 4'd0;

        // Hold reset low for the first 2 clock cycles
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Sweep all 256 combinations
        for (ia = 0; ia < 16; ia = ia + 1) begin
            for (ib = 0; ib < 16; ib = ib + 1) begin

                // Drive on the falling edge, away from the sampling edge
                @(negedge clk);
                a = ia[3:0];
                b = ib[3:0];

                // Latency is 2 cycles: inputs are captured at the first rising
                // edge, the product is captured at the second.
                @(posedge clk);   // edge 1: a, b -> a_reg, b_reg
                @(posedge clk);   // edge 2: array result -> p
                @(negedge clk);   // sample mid-cycle, clear of the clock edge.
                                  // Gate-level cells carry a UNIT_DELAY, so
                                  // sampling right at the edge races with Q
                                  // and reads the previous vector's result.

                expected = ia[3:0] * ib[3:0];
                checked  = checked + 1;

                if (p !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH: a=%0d b=%0d expected=%0d (%b) got=%0d (%b) at time %0t",
                             ia, ib, expected, expected, p, p, $time);
                end
            end
        end

        // Exactly one summary line
        if (errors == 0) begin
            $display("PASS: %0d vectors checked, %0d errors", checked, errors);
        end else begin
            $display("FAIL: %0d vectors checked, %0d errors", checked, errors);
        end

        $finish;
    end

endmodule

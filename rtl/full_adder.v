// ---------------------------------------------------------------------------
// full_adder.v
//
// One-bit full adder, written with assign statements (assignment section 5).
//
//   sum  = three-input XOR of the inputs
//   cout = majority function: 1 when two or more inputs are 1
// ---------------------------------------------------------------------------

`default_nettype none

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule

`default_nettype wire

// ---------------------------------------------------------------------------
// mult_array.v
//
// 4-bit x 4-bit unsigned array multiplier, 8-bit registered product.
//
// Structure (assignment sections 2 and 5):
//   1. Input registers  - a and b captured into 4-bit registers on posedge clk
//   2. Combinational array - 16 AND gates + 12 full adders, built from the
//      REGISTERED values, wired exactly as the table in section 2
//   3. Output register  - 8-bit result captured into p on posedge clk
//
// Flip-flops: 4 (a_reg) + 4 (b_reg) + 8 (p) = 16
// Latency   : 2 clock cycles (inputs captured at edge 1, product at edge 2)
// Throughput: one result per clock cycle
//
// Reset is asynchronous and active low; it clears all registers to 0.
// The * operator is not used anywhere in this file.
//
// Connection table implemented below (pp_i[j] = a_reg[j] AND b_reg[i]):
//
//   Row 0: no adders
//          p[0] = pp0[0]
//          r0   = {0, pp0[3], pp0[2], pp0[1]}
//   Row 1: adder j takes pp1[j], r0[j], carry c1[j]   (c1[0] = 0)
//          p[1] = s1[0]
//          r1   = {c1[4], s1[3], s1[2], s1[1]}
//   Row 2: adder j takes pp2[j], r1[j], carry c2[j]   (c2[0] = 0)
//          p[2] = s2[0]
//          r2   = {c2[4], s2[3], s2[2], s2[1]}
//   Row 3: adder j takes pp3[j], r2[j], carry c3[j]   (c3[0] = 0)
//          p[3]   = s3[0]
//          p[7:4] = {c3[4], s3[3], s3[2], s3[1]}
// ---------------------------------------------------------------------------

`default_nettype none

module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    // -----------------------------------------------------------------------
    // 1. Input registers
    // -----------------------------------------------------------------------
    reg [3:0] a_reg;
    reg [3:0] b_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'd0;
            b_reg <= 4'd0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // -----------------------------------------------------------------------
    // 2. Combinational array
    // -----------------------------------------------------------------------

    // Partial products: 4 rows x 4 AND gates = 16 AND gates.
    // pp_i[j] = a_reg[j] AND b_reg[i]
    wire [3:0] pp0;
    wire [3:0] pp1;
    wire [3:0] pp2;
    wire [3:0] pp3;

    assign pp0 = a_reg & {4{b_reg[0]}};
    assign pp1 = a_reg & {4{b_reg[1]}};
    assign pp2 = a_reg & {4{b_reg[2]}};
    assign pp3 = a_reg & {4{b_reg[3]}};

    // Bits passed down from each row to the next
    wire [3:0] r0;
    wire [3:0] r1;
    wire [3:0] r2;

    // Row sums and carry chains. c*[0] is the carry-in of each row and is 0.
    wire [3:0] s1;
    wire [3:0] s2;
    wire [3:0] s3;
    wire [4:0] c1;
    wire [4:0] c2;
    wire [4:0] c3;

    assign c1[0] = 1'b0;
    assign c2[0] = 1'b0;
    assign c3[0] = 1'b0;

    // Row 0 is only AND gates: its lowest bit is already p[0], the other three
    // bits pass down to row 1 with a zero in the top position.
    assign r0 = {1'b0, pp0[3], pp0[2], pp0[1]};

    genvar j;
    generate
        // Row 1: 4 full adders
        for (j = 0; j < 4; j = j + 1) begin : row1
            full_adder u_fa (
                .a    (pp1[j]),
                .b    (r0[j]),
                .cin  (c1[j]),
                .sum  (s1[j]),
                .cout (c1[j+1])
            );
        end

        // Row 2: 4 full adders
        for (j = 0; j < 4; j = j + 1) begin : row2
            full_adder u_fa (
                .a    (pp2[j]),
                .b    (r1[j]),
                .cin  (c2[j]),
                .sum  (s2[j]),
                .cout (c2[j+1])
            );
        end

        // Row 3: 4 full adders
        for (j = 0; j < 4; j = j + 1) begin : row3
            full_adder u_fa (
                .a    (pp3[j]),
                .b    (r2[j]),
                .cin  (c3[j]),
                .sum  (s3[j]),
                .cout (c3[j+1])
            );
        end
    endgenerate

    // Lowest sum bit of each row is a finished product bit; the other three
    // sum bits and the row carry-out pass down to the next row.
    assign r1 = {c1[4], s1[3], s1[2], s1[1]};
    assign r2 = {c2[4], s2[3], s2[2], s2[1]};

    // Assembled 8-bit product, before the output register.
    wire [7:0] p_next;

    assign p_next = {c3[4], s3[3], s3[2], s3[1],   // p[7:4]
                     s3[0],                        // p[3]
                     s2[0],                        // p[2]
                     s1[0],                        // p[1]
                     pp0[0]};                      // p[0]

    // -----------------------------------------------------------------------
    // 3. Output register
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 8'd0;
        end else begin
            p <= p_next;
        end
    end

endmodule

`default_nettype wire

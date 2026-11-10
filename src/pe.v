// Processing element (PE) for an output-stationary systolic array.
// Every cycle: multiply the two incoming values, add to the local accumulator,
// and pass both inputs on (registered) to the right and downward neighbors.
module pe #(
    parameter DW = 8,    // input data width (signed)
    parameter AW = 32    // accumulator width (signed)
) (
    input  wire                  clk,
    input  wire                  rst,    // synchronous, active high
    input  wire signed [DW-1:0]  a_in,   // from the left neighbor
    input  wire signed [DW-1:0]  b_in,   // from the top neighbor
    output reg  signed [DW-1:0]  a_out,  // to the right neighbor
    output reg  signed [DW-1:0]  b_out,  // to the bottom neighbor
    output reg  signed [AW-1:0]  acc     // this PE's element of C
);
    always @(posedge clk) begin
        if (rst) begin
            a_out <= 0;
            b_out <= 0;
            acc   <= 0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
            acc   <= acc + a_in * b_in;
        end
    end
endmodule

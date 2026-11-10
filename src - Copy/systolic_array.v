// N x N output-stationary systolic array for matrix multiplication C = A x B.
// Row i of A enters on the left edge (delayed i cycles), column j of B enters
// on the top edge (delayed j cycles). PE(i,j) accumulates C[i][j].
// Inputs and outputs are flattened vectors, one element per row/column/PE.
module systolic_array #(
    parameter N  = 4,
    parameter DW = 8,
    parameter AW = 32
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire [N*DW-1:0]      a_in,    // a_in[i*DW +: DW]  -> row i, left edge
    input  wire [N*DW-1:0]      b_in,    // b_in[j*DW +: DW]  -> column j, top edge
    output wire [N*N*AW-1:0]    c_out    // c_out[(i*N+j)*AW +: AW] = C[i][j]
);
    // a_w[i*(N+1)+j] : value entering PE(i,j) from the left (j = N is the unused right edge)
    // b_w[i*N+j]     : value entering PE(i,j) from the top  (i = N is the unused bottom edge)
    wire signed [DW-1:0] a_w   [0:N*(N+1)-1];
    wire signed [DW-1:0] b_w   [0:(N+1)*N-1];
    wire signed [AW-1:0] acc_w [0:N*N-1];

    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_row
            assign a_w[i*(N+1)] = a_in[i*DW +: DW];
            for (j = 0; j < N; j = j + 1) begin : g_col
                if (i == 0) begin : g_top
                    assign b_w[j] = b_in[j*DW +: DW];
                end
                pe #(.DW(DW), .AW(AW)) u_pe (
                    .clk  (clk),
                    .rst  (rst),
                    .a_in (a_w[i*(N+1)+j]),
                    .b_in (b_w[i*N+j]),
                    .a_out(a_w[i*(N+1)+j+1]),
                    .b_out(b_w[(i+1)*N+j]),
                    .acc  (acc_w[i*N+j])
                );
                assign c_out[(i*N+j)*AW +: AW] = acc_w[i*N+j];
            end
        end
    endgenerate
endmodule

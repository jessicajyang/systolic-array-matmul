`timescale 1ns/1ps
// Self-checking testbench: multiplies random signed int8 matrices and compares
// every element of the result against a reference computed in the testbench.
module tb_systolic_array;
    parameter N         = 4;
    parameter DW        = 8;
    parameter AW        = 32;
    parameter NUM_TESTS = 100;

    reg                  clk = 0;
    reg                  rst = 1;
    reg  [N*DW-1:0]      a_in = 0;
    reg  [N*DW-1:0]      b_in = 0;
    wire [N*N*AW-1:0]    c_out;

    systolic_array #(.N(N), .DW(DW), .AW(AW)) dut (
        .clk(clk), .rst(rst), .a_in(a_in), .b_in(b_in), .c_out(c_out)
    );

    always #5 clk = ~clk;   // 100 MHz simulation clock

    reg signed [DW-1:0] A     [0:N*N-1];
    reg signed [DW-1:0] B     [0:N*N-1];
    reg signed [AW-1:0] C_ref [0:N*N-1];
    reg signed [AW-1:0] got;
    integer i, j, k, t, trial;
    integer sum, errors, total_errors, cycles;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_systolic_array);
        total_errors = 0;

        for (trial = 0; trial < NUM_TESTS; trial = trial + 1) begin
            // 1. random matrices (truncation of $random gives -128..127 for int8)
            for (i = 0; i < N*N; i = i + 1) begin
                A[i] = $random;
                B[i] = $random;
            end

            // 2. reference result
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1) begin
                    sum = 0;
                    for (k = 0; k < N; k = k + 1)
                        sum = sum + A[i*N+k] * B[k*N+j];
                    C_ref[i*N+j] = sum;
                end

            // 3. reset (inputs change on the falling edge to avoid races)
            rst = 1; a_in = 0; b_in = 0;
            repeat (2) @(negedge clk);
            rst = 0;

            // 4. feed skewed inputs: row i delayed by i cycles, column j by j cycles
            cycles = 0;
            for (t = 0; t < 3*N - 2; t = t + 1) begin
                for (i = 0; i < N; i = i + 1) begin
                    k = t - i;
                    if (k >= 0 && k < N) a_in[i*DW +: DW] = A[i*N+k];
                    else                 a_in[i*DW +: DW] = 0;
                end
                for (j = 0; j < N; j = j + 1) begin
                    k = t - j;
                    if (k >= 0 && k < N) b_in[j*DW +: DW] = B[k*N+j];
                    else                 b_in[j*DW +: DW] = 0;
                end
                @(negedge clk);
                cycles = cycles + 1;
            end

            // 5. compare
            errors = 0;
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1) begin
                    got = c_out[(i*N+j)*AW +: AW];
                    if (got !== C_ref[i*N+j]) begin
                        errors = errors + 1;
                        $display("MISMATCH trial %0d C[%0d][%0d]: got %0d, expected %0d",
                                 trial, i, j, got, C_ref[i*N+j]);
                    end
                end
            total_errors = total_errors + errors;
        end

        $display("------------------------------------------------");
        $display("N = %0d | tests = %0d | cycles per multiply = %0d (3N-2 = %0d)",
                 N, NUM_TESTS, cycles, 3*N-2);
        if (total_errors == 0) $display("PASS: all %0d tests matched the reference", NUM_TESTS);
        else                   $display("FAIL: %0d mismatches", total_errors);
        $finish;
    end
endmodule

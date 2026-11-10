"""Cycle-accurate Python model of the systolic array, mirroring the RTL register
for register. Used to (1) check the dataflow/timing and (2) produce the expected
cycle counts and plot that the Verilog simulation should reproduce.

Run:  python3 scripts/model.py
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def systolic_matmul(A, B):
    """Returns (C, cycles). Same dataflow as src/pe.v + src/systolic_array.v."""
    N = A.shape[0]
    a_reg = np.zeros((N, N), dtype=np.int64)   # a_out registers
    b_reg = np.zeros((N, N), dtype=np.int64)   # b_out registers
    acc = np.zeros((N, N), dtype=np.int64)
    cycles = 3 * N - 2
    for t in range(cycles):
        a_edge = np.array([A[i, t - i] if 0 <= t - i < N else 0 for i in range(N)])
        b_edge = np.array([B[t - j, j] if 0 <= t - j < N else 0 for j in range(N)])
        a_in = np.zeros((N, N), dtype=np.int64)
        b_in = np.zeros((N, N), dtype=np.int64)
        a_in[:, 0] = a_edge
        a_in[:, 1:] = a_reg[:, :-1]
        b_in[0, :] = b_edge
        b_in[1:, :] = b_reg[:-1, :]
        acc = acc + a_in * b_in      # all registers update together
        a_reg, b_reg = a_in, b_in
    return acc, cycles


def main():
    rng = np.random.default_rng(0)
    sizes = [2, 4, 8, 16, 32]
    rows = []
    for N in sizes:
        for _ in range(100):
            A = rng.integers(-128, 128, (N, N), dtype=np.int64)
            B = rng.integers(-128, 128, (N, N), dtype=np.int64)
            C, cyc = systolic_matmul(A, B)
            assert np.array_equal(C, A @ B), f"mismatch at N={N}"
        seq = N ** 3                       # 1 multiply-accumulate per cycle
        rows.append((N, N * N, cyc, seq, seq / cyc, N ** 3 / (N * N * cyc)))

    print("| N | PEs | Systolic cycles (3N-2) | Sequential cycles (N^3) | Speedup | PE utilization |")
    print("|---|-----|------------------------|-------------------------|---------|----------------|")
    for N, pes, cyc, seq, sp, util in rows:
        print(f"| {N} | {pes} | {cyc} | {seq} | {sp:.1f}x | {util*100:.0f}% |")

    Ns = [r[0] for r in rows]
    fig, ax = plt.subplots(1, 2, figsize=(10, 4))
    ax[0].loglog(Ns, [r[2] for r in rows], "o-", label="Systolic (3N-2)")
    ax[0].loglog(Ns, [r[3] for r in rows], "s-", label="Sequential (N^3)")
    ax[0].set_xlabel("Matrix size N"); ax[0].set_ylabel("Cycles for one N x N multiply")
    ax[0].set_title("Cycles vs matrix size"); ax[0].legend(); ax[0].grid(True, which="both", alpha=0.3)
    ax[1].plot(Ns, [r[4] for r in rows], "o-")
    ax[1].set_xlabel("Matrix size N"); ax[1].set_ylabel("Speedup over sequential")
    ax[1].set_title("Speedup (uses N^2 PEs)"); ax[1].grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig("results/cycles_vs_n.png", dpi=150)


if __name__ == "__main__":
    main()

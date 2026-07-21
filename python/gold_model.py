import numpy as np
import os

N = 4 # dimension of array, NxN
DATA_W = 8 # operand bit width, (UINT8)
ACC_W = 16 #accumulator bit width (UINT16)

mask_data = (1 << DATA_W) - 1 # Replaces hardcoded 0xFF for clean scaling
mask_acc = (1 << ACC_W) - 1 # detects if the registered bits overflow or not

np.random.seed(42) # seed

A = np.random.randint(0, 1, << DATA_W, size=(N,N), dtype=np.uint16) # full 8 bit range
B = np.random.randint(0, 1, << DATA_W, size=(N,N), dtype=np.uint16)

C = np.matmul(A,B)

print("=" * 60)
print("--------------PYTHON GOLDEN MODEL: TEST VECTORS--------------")
print("=" * 60)
print("Matrix A (Original Input):")
print(A)
print("\nMatrix B (Original Input):")
print(B)
print("\nExpected Matrix C (Gold Standard Output):")
print(C)
print("=" * 60)

# Now, we check if the hardware accumulators overflow ACC_W
max_num = np.max(C)
if max_num > mask_acc:
        print(f'Warning: Overflow detected. Max value {max_num} exceeds {ACC_W}-bit max capacity ({mask_acc}).\n')


# File generation for RTL testbench

with open('A_matrix.txt', 'w') as f:
        np.savetxt(f, A, fmt="%d")

with open('B_matrix.txt', 'w') as f:
        np.savetxt(f, B, fmt='%d')

with open('expected_C_matrix.txt', 'w') as f:
    for row in range(N):
        for col in range(N):
            f.write(f"{C[row, col] & mask_acc:04X}\n")

# Total clock cycles needed to feed N x N skew network = (2 * N - 1)
# Cycle 0: A[0,0] and B[0,0] enter
# Cycle 2*N - 2: A[N-1, N-1] and B[N-1, N-1] enter
with open("matrix_A.txt", "w") as f_a, open("matrix_B.txt", "w") as f_b:
    for t in range(2 * N - 1):
        a_packed_cycle = 0
        b_packed_cycle = 0
        
        for i in range(N):
            # Matrix A Skew Timing:
            # Row i is delayed by i cycles in hardware.
            # Thus at time t, Row i receives column element (t - i).
            col_a = t - i
            a_val = A[i, col_a] if 0 <= col_a < N else 0
            a_packed_cycle |= (int(a_val) & MASK_DATA) << (i * DATA_W)

            # Matrix B Skew Timing:
            # Column j (mapped here as index i) is delayed by i cycles in hardware.
            # Thus at time t, Column i receives row element (t - i).
            row_b = t - i
            b_val = B[row_b, i] if 0 <= row_b < N else 0
            b_packed_cycle |= (int(b_val) & MASK_DATA) << (i * DATA_W)

        f_a.write(f"{a_packed_cycle:08X}\n")
        f_b.write(f"{b_packed_cycle:08X}\n")

print("[INFO] Generated matrix_A.txt, matrix_B.txt, expected_C.txt, A_matrix.txt, B_matrix.txt")
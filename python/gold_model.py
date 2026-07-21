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
import numpy as np
import os

# Configuration Parameters
N = 4       # Dimension of array (N x N)
DATA_W = 8  # Operand bit width (UINT8)
ACC_W = 16  # Accumulator bit width (UINT16)

# Bit Masks
mask_data = (1 << DATA_W) - 1 # Dynamic mask replacing hardcoded 0xFF
mask_acc = (1 << ACC_W) - 1   # Detects accumulator overflow

np.random.seed(42) # Deterministic seed for reproducible testing

A = np.random.randint(0, 1 << DATA_W, size=(N, N), dtype=np.uint16) 
B = np.random.randint(0, 1 << DATA_W, size=(N, N), dtype=np.uint16)

C = np.matmul(A, B)

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

# Check for hardware accumulator overflow
max_num = np.max(C)
if max_num > mask_acc:
    print(f'Warning: Overflow detected. Max value {max_num} exceeds {ACC_W}-bit max capacity ({mask_acc}).\n')


# File Generation for RTL Testbench

with open('A_matrix.txt', 'w') as f:
    np.savetxt(f, A, fmt="%d")

with open('B_matrix.txt', 'w') as f:
    np.savetxt(f, B, fmt='%d')

# Standardized filename to expected_C.txt
with open('expected_C.txt', 'w') as f:
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
            # Fixed Bug: Changed MASK_DATA to lower-case mask_data
            a_packed_cycle |= (int(a_val) & mask_data) << (i * DATA_W)

            # Matrix B Skew Timing:
            # Column j (mapped here as index i) is delayed by i cycles in hardware.
            # Thus at time t, Column i receives row element (t - i).
            row_b = t - i
            b_val = B[row_b, i] if 0 <= row_b < N else 0
            b_packed_cycle |= (int(b_val) & mask_data) << (i * DATA_W)

        f_a.write(f"{a_packed_cycle:08X}\n")
        f_b.write(f"{b_packed_cycle:08X}\n")

print("[INFO] Generated matrix_A.txt, matrix_B.txt, expected_C.txt, A_matrix.txt, B_matrix.txt")

# Once the Verilog simulation writes hardware_output.txt, run this section to verify!
hw_file = "hardware_output.txt"
if os.path.exists(hw_file):
    print("\n" + "=" * 60)
    print("---------AUTOMATED HARDWARE VS SOFTWARE CHECK--------- ")
    print("=" * 60)
    
    hw_results = []
    with open(hw_file, "r") as f:
        for line in f:
            if line.strip():
                hw_results.append(int(line.strip(), 16))
                
    expected_results = (C & mask_acc).flatten().tolist()
    
    if len(hw_results) != N * N:
        print(f"[ERROR] Output count mismatch! Expected {N*N} outputs, but found {len(hw_results)} in '{hw_file}'.")
    else:
        mismatches = 0
        for idx, (hw, exp) in enumerate(zip(hw_results, expected_results)):
            row = idx // N
            col = idx % N
            if hw != exp:
                print(f"[FAIL] Result[{row}][{col}] -> HW: {hw} (0x{hw:04X}) | Expected: {exp} (0x{exp:04X})")
                mismatches += 1
            
        if mismatches == 0 and len(hw_results) == (N * N):
            print("SUCCESS: RTL Hardware Output perfectly matches Python Golden Model! <<<")
        else:
            print(f"FAILURE: Found {mismatches} mismatches out of {N*N} values. <<<")
else:
    print("\n[NOTE] 'hardware_output.txt' not found yet. Run Verilog simulation to perform auto-check.")
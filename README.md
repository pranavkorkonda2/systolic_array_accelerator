# Parameterized INT8 Systolic Array AI Accelerator

![Verilog](https://img.shields.io/badge/Language-Verilog_2001-blue.svg)
![FPGA](https://img.shields.io/badge/Target-Xilinx_Kintex--7-orange.svg)
![Toolchain](https://img.shields.io/badge/Toolchain-Vivado_2025.2-red.svg)
![Timing](https://img.shields.io/badge/Timing-Met_(+3.156ns_WNS)-brightgreen.svg)
![Python](https://img.shields.io/badge/Verification-Python_3.x-yellow.svg)

> **A fully parameterized, hardware-skewed, output-stationary $N \times N$ matrix multiplication engine ($C = A \times B$) engineered in Verilog HDL and target-optimized for AMD Xilinx Kintex-7 FPGAs.**

---

## Executive Summary & Performance Highlights

This accelerator addresses the memory bandwidth bottleneck of Von Neumann architectures by implementing a **spatial computing grid** with on-chip input staggering. Designed for INT8 AI/ML matrix workloads, the design achieves full timing closure without relying on external delay buffers.

| Metric | Specification / Result | Impact / Engineering Note |
| :--- | :--- | :--- |
| **Grid Configuration** | $N = 4$, INT8 inputs, 32-bit accumulators | Fully parameterized (`DATA_W`, `ACC_W`, `N`) |
| **Max Clock Frequency ($F_{\max}$)** | **146.11 MHz** ($T_{\min} = 6.84\text{ ns}$) | Synthesized & routed on Kintex-7 (`xc7k70tfbv676-1`) |
| **Worst Negative Slack (WNS)** | **$+3.156\text{ ns}$** | Clean timing closure at 100 MHz target clock |
| **Peak Throughput** | **4.675 GOP/s** @ $F_{\max}$ | Direct continuous systolic MAC pipelining |
| **Logic Resource Cost** | 1,371 LUTs (3.34%), 572 FFs (0.70%) | Ultra-compact control logic & distributed MACs |
| **Verification** | 100% Bit-Exact Match | Python Golden Model co-simulation framework |

```text
                                     System Dataflow at a Glance
   
                           B_in[0]       B_in[1]       B_in[2]       B_in[3]
                              │             │             │             │
                         ┌────┴────┐   ┌────┴────┐   ┌────┴────┐   ┌────┴────┐
                         │ Skew[0] │   │ Skew[1] │   │ Skew[2] │   │ Skew[3] │
                         └────┬────┘   └────┬────┘   └────┬────┘   └────┬────┘
                              ▼             ▼             ▼             ▼
A_in[0] ──► [Skew 0] ──► [ PE0,0 ] ──► [ PE0,1 ] ──► [ PE0,2 ] ──► [ PE0,3 ]
                             │             │             │             │
                             ▼             ▼             ▼             ▼
A_in[1] ──► [Skew 1] ──► [ PE1,0 ] ──► [ PE1,1 ] ──► [ PE1,2 ] ──► [ PE1,3 ]
                             │             │             │             │
                             ▼             ▼             ▼             ▼
A_in[2] ──► [Skew 2] ──► [ PE2,0 ] ──► [ PE2,1 ] ──► [ PE2,2 ] ──► [ PE2,3 ]
                             │             │             │             │
                             ▼             ▼             ▼             ▼
A_in[3] ──► [Skew 3] ──► [ PE3,0 ] ──► [ PE3,1 ] ──► [ PE3,2 ] ──► [ PE3,3 ]
```

## Quick Start

### Prerequisites
* **Synthesis & Simulation:** AMD Xilinx Vivado (2025.2 or compatible)
* **Golden Model Verification:** Python 3.x with NumPy (`pip install numpy`)

---

### 1. Verification & Simulation

#### Option A: Command Line / Terminal
```bash
# Clone repository and enter directory
git clone [https://github.com/pranavkorkonda2/systolic_array_accelerator.git](https://github.com/pranavkorkonda2/systolic_array_accelerator.git)
cd systolic_array_accelerator

# Run Python Golden Model to generate reference test vectors
python python/golden_model.py

# Launch Vivado behavioral simulation in batch mode
vivado -mode batch -source -notrace -tclbatch - << 'EOF'
open_project systolic_array_accelerator.xpr
launch_simulation
run all
close_project
EOF
```
#### Option B: Vivado GUI & Tcl Console
Open Vivado, then open project `systolic_array_accelerator.xpr`.
Run simulation via Tcl Console:
```
launch_simulation
run all
```
Generate and verify test matrices in terminal:
```bash
python python/golden_model.py
```

### 2. Synthesis & Timing Verification
Run full Synthesis, Implementation, and Report generation via command line or Vivado Tcl Console:
```bash
# Open project (skip if already open in GUI)
open_project systolic_array_accelerator.xpr

# Set target device
set_property part xc7k70tfbv676-1 [current_project]

# Run Synthesis & Implementation pipeline
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Open implementation & display timing / utilization reports
open_run impl_1
report_timing_summary -file docs/timing_summary.rpt
report_utilization -file docs/utilization_summary.rpt
```


## Processing Element (PE) Design (`systolic_mac_pe.v`)

Each PE computes an output-stationary MAC operation:

$$\mathrm{acc\_reg} \leftarrow \mathrm{acc\_reg} + (A_{\text{in}} \times B_{\text{in}})$$

Operands $A$ and $B$ along with control valid flags are registered on every clock cycle and forwarded to neighboring PEs in the mesh to maintain systolic rhythm.
```
               B_in , valid_in
                     │
                     ▼
             ┌───────────────┐
  A_in ─────►│  Registers &  ├─────► A_out
             │  MAC Compute  │
             └───────┬───────┘
                     │
                     ▼
               B_out , valid_out
```
![PE Waveform](images/wave_pe.png)

> **Waveform Verification Highlights (`wave_pe.png`):**
> * **Synchronous Accumulator Reset:** `RST_tb` clears `acc_out_tb` to `0` at 20 ns.
> * **Pipelined MAC Execution:** At 50 ns, inputs A = 3 and B = 4 compute 3 x 4 = 12. On the following cycle (70 ns), inputs A = 2 and B = 5 accumulate: 12 + (2 x 5) = 22.
> * **Registered Operand Forwarding:** Input values A and B are registered and forwarded to `A_out_tb` and `B_out_tb` on the subsequent clock edge with zero data corruption.

---

## Systolic Compute Mesh Design (`systolic_compute_mesh.v`)

The compute engine consists of a structural NxN spatial grid of PEs. Each PE maintains a stationary 32-bit accumulator while forwarding registered 8-bit operands ($A$ horizontally, $B$ vertically) alongside single-bit valid control signals. 

Data streams diagonally through the array mesh, allowing each input element to be reused $N$ times across the spatial grid, significantly reducing external memory bandwidth requirements.

![Compute Mesh Waveform](images/wave_mesh.png)

> **Waveform Verification Highlights (`wave_mesh.png`):**
> * **Inter-PE Data Propagation:** Inputs `A_in` = `0x00000002` and `B_in` = `0x00000003` drive channel 0 at 60 ns (`valid_in` = `0001`).
> * **Downstream Forwarding:** Registered outputs `A_out` and `B_out` reflect forwarded operands on the next clock cycle (120 ns) with matching `valid_out` flags (`0001`).
> * **Spatial Accumulation:** PE accumulators capture product values (2 x 3 = 6) directly into packed bus `acc_out[63:0]`.

---

## Input Skew Network Design (`input_skew_network.v` and `skewer_buffer.v`)

To synchronize data arrival at downstream PEs in an output-stationary array, input operands must be temporally staggered. The hardware skew network utilizes shift-register delay chains to stagger inputs by row and column index:

1. Row `i` of matrix `A` is delayed by `i` clock cycles.
2. Column `j` of matrix `B` is delayed by `j` clock cycles.

This ensures that matching operand pairs `A_ik` and `B_kj` converge at `PE_ij` during the exact same clock cycle without requiring external software-driven delay buffers.

![Input Skew Waveform](images/wave_skew.png)

> **Waveform Verification Highlights (`wave_skew.png`):**
> * **Simultaneous Packed Input:** Parallel packed buses `A_in` = `0xddccbbaa` and `B_in` = `0x44332211` arrive simultaneously at 60 ns (`valid_in` = `1111`).
> * **Staggered Diagonal Output:** Shift registers delay output channels progressively across 4 consecutive cycles:
>   * **Cycle 1 (60 ns):** `skewed_valid_out` = `0001` (Byte 0: `0xaa` / `0x11`)
>   * **Cycle 2 (80 ns):** `skewed_valid_out` = `0010` (Byte 1: `0xbb` / `0x22`)
>   * **Cycle 3 (100 ns):** `skewed_valid_out` = `0100` (Byte 2: `0xcc` / `0x33`)
>   * **Cycle 4 (120 ns):** `skewed_valid_out` = `1000` (Byte 3: `0xdd` / `0x44`)

## Finite State Machine (FSM) Execution (`controller_fsm.v`)

The execution lifecycle is governed by a 4-state controller:
```
    ┌──────────┐
    │  IDLE    │◄─────────────────────────────┐
    └────┬─────┘                              │
         │ START                              │
         ▼                                    │
    ┌──────────┐                              │
    │  CLEAR   │ (Synchronous ACC Reset)      │
    └────┬─────┘                              │
         │                                    │
         ▼                                    │
    ┌──────────┐                              │
    │ COMPUTE  │ (Active Data Streaming)      │
    └────┬─────┘                              │
         │ cycle_counter == (3*N - 1)         │
         ▼                                    │
    ┌──────────┐                              │
    │OUTPUT_VAL│──────────────────────────────┘
    └──────────┘ DONE = 1
```

1. IDLE: Controller awaits `START` pulse.
2. CLEAR: Asserts `CLEAR_ACC` for 1 clock cycle to clear all NxN accumulators prior to computation.
3. COMPUTE: Enables dataflow into input skew network and tracks cycle latency (3N - 1 cycles).
4. OUTPUT_VALID: Asserts `DONE` pulse, indicating complete matrix product C is stable on output buses.

---

## Top-Level System Integration (`systolic_array_top.v`)

The systolic_array_top.v module wraps the Controller FSM, Input Skew Network, and Systolic Compute Mesh into a unified accelerator interface. It abstracts internal clock-domain alignment, state transitions, and mesh wiring, presenting a simple control interface to the host system.

### Top-Level Interface & Execution Flow
    1. Data Buses: Accepts packed 32-bit input buses (A_in and B_in) containing N=4 parallel INT8 matrix streams.
    2. Control Flags: Driven by `CLK`, `RST`, and a single-cycle `START` trigger pulse.
    3. Output Interface: Exposes a flattened 256-bit output bus (acc_out[255:0]) representing all N^2 32-bit accumulated matrix cells, gated by a DONE status flag and output `valid_out` lines.

So, when `START` is pulsed high, the wrapper handles accumulator clearing, streams packed vectors through the input skewer, and asserts `DONE` once matrix multiplication completes.

![Top-Level System Waveform](images/wave_systolic_array1.png)

> **Waveform Verification Highlights (`wave_systolic_array1.png`):**
> * **FSM Execution Lifecycle:** A single-cycle `START` pulse at 110 ns triggers synchronous accumulator reset followed by active matrix streaming.
> * **Systolic Pipeline Wavefront:** Mesh valid signals (`valid_out`) progressively activate across the grid (`0001` -> `0011` -> `0111` -> `1111`).
> * **Execution Completion:** The controller asserts `DONE` at 390 ns, locking the final 4 x 4 result matrix into the 256-bit bus `acc_out` (`0xa112faf69426caffb1d502366e54c31...`).

---

## Verification Methodology

Verification employs a co-simulation flow linking Python software models with Verilog testbenches:
```

┌──────────────────────┐        Generates Test Vectors       ┌──────────────────────┐
│  golden_model.py     │ ──────────────────────────────────► │  matrix_A/B.txt      │
└──────────┬───────────┘                                     └──────────┬───────────┘
           │ Calculates Expected Matrix C                               │
           ▼                                                            ▼
┌──────────────────────┐       Compares Hardware Output      ┌──────────────────────┐
│   expected_C.txt     │ ◄────────────────────────────────── │  tb_systolic_top.v   │
└──────────────────────┘                                     └──────────────────────┘
```

1. `golden_model.py` generates pseudo-random input matrices `A` and `B`, packs them into hex-formatted cycle streams, and calculates gold-standard output `C = A x B`.
2. Verilog testbench loads inputs via `$readmemh`, drives `systolic_array_top`, and dumps execution outputs to `hardware_output.txt`.
3. Automated check script compares simulation results against expected output values with zero error tolerance.

---

## Synthesis & FPGA Implementation Results

Implemented in **AMD Xilinx Vivado 2025.2** targeting Kintex-7 (`xc7k70tfbv676-1`).

### Resource Utilization Summary

| Resource | Used | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **Slice LUTs** | 1,371 | 41,000 | 3.34% |
| **Slice Registers (FFs)** | 572 | 82,000 | 0.70% |
| **DSP48E1 Blocks** | 0 | 240 | 0.00% |
| **Block RAM (BRAM)** | 0 | 135 | 0.00% |

> **Note on DSP Utilization:** Multipliers (8x8-bit) synthesized into LUT and carry chain logic (`CARRY4`) under default Vivado optimization settings. Larger configurations (N >= 8) can mandate DSP instantiation via synthesis directives.

### Timing Summary

* **Target Clock Period:** 10.00 ns (100.00 MHz)
* **Worst Negative Slack (WNS):** +3.156 ns
* **Worst Hold Slack (WHS):** +0.103 ns
* **Minimum Clock Period (T_min):** 10.00 ns - 3.156 ns = 6.844 ns
* **Maximum Frequency (F_max):** 146.11 MHz

---

## Architectural Performance Analysis

### Latency and Throughput Metrics (N = 4)

* **Total Operations:** N^3 = 64 MACs (128 FLOP equivalents)
* **Latency:** 13 cycles (130.00 ns at 100 MHz, 88.97 ns at 146.11 MHz)
* **Compute Efficiency:** 4.92 MACs/cycle average across execution pass (16 MACs/cycle peak array capability)
* **Peak Compute Throughput:** **4.675 GOP/s** at F_max

### Key Architectural Concepts & Trade-offs
1. Spatial Computing vs. Von Neumann Architectures:
   Von Neumann designs suffer from memory bandwidth bottlenecks fetching instructions and operands repeatedly from memory. Systolic arrays stream data across a spatial grid of processing elements, reusing inputs N times across array dimensions and drastically reducing memory access bandwidth.
2. Output-Stationary Dataflow:
   In this design, partial sums remain stationary within PE accumulators while weights/inputs stream through. This minimizes register movement power for high-precision accumulators compared to weight-stationary or input-stationary configurations.
3. Scalability & Bottlenecks:
   A. I/O Routing Bottleneck: Flattened wide output buses (N^2 x ACC_W) scale quadricly with array dimension. For N >= 16 output serialization or AXI4 stream interfaces are required.
   B. Clock Distribution Skew: Large spatial meshes require balanced clock trees to prevent setup/hold violations across array boundaries.

---

## Repository Structure
```text
systolic_array_accelerator/
├── docs/                               # Timing and Utilization reports
├── images/                             # Waveform & architecture screenshots
├── python/
│   └── golden_model.py                 # Golden reference model & vector generator
├── systolic_array_accelerator.srcs/
│   ├── constrs_1/new/
│   │   └── timing_constraints.xdc      # Primary timing & clock constraints
│   ├── sim_1/
│   │   ├── imports/                    # Test vector files (matrix_A, matrix_B, etc.)
│   │   └── new/
│   │       ├── tb_compute_mesh.v       # Integration testbench for NxN mesh
│   │       ├── tb_pe.v                 # Unit testbench for PE (MAC + forwarding)
│   │       ├── tb_skew_network.v       # Unit testbench for skewing pipelines
│   │       └── tb_systolic_array.v     # Full-system testbench (top-level)
│   └── sources_1/new/
│       ├── controller_fsm.v            # State controller logic
│       ├── input_skew_network.v        # Hardware skewing logic
│       ├── skewer_buffer.v             # Shift register delay module
│       ├── systolic_array_top.v        # Top-level system wrapper
│       ├── systolic_compute_mesh.v     # N x N Structural array mesh
│       └── systolic_mac_pe.v           # Processing Element MAC design
├── .gitignore
├── README.md
└── systolic_array_accelerator.xpr      # Vivado project file
```
## Author and Contact
    1. Developer: Pranav Korkonda
    2. Email: pranavkorkonda2@gmail.com
    3. LinkedIn: https://www.linkedin.com/in/pranav-korkonda-5b2ab7397/
    4. GitHub: https://github.com/pranavkorkonda2
    

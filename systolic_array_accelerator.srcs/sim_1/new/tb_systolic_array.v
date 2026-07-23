`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 06:44:21 AM
// Design Name: 
// Module Name: tb_systolic_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module tb_systolic_array;

    parameter N = 4;
    parameter DATA_W = 8;
    parameter ACC_W  = 16;

    localparam CYCLES = (2 * N) - 1;
    localparam TOTAL_OUTPUTS = N * N;

    // Clock / Control Signals
    reg CLK;
    reg RST;
    reg START;

    // DUT I/O Signals
    reg  [N*DATA_W-1:0] A_in;
    reg  [N*DATA_W-1:0] B_in;

    wire [N*N*ACC_W-1:0] acc_out;
    wire [N-1:0] valid_out;
    wire DONE;

    // Testbench Memories
    reg [N*DATA_W-1:0] stream_A [0:CYCLES-1];
    reg [N*DATA_W-1:0] stream_B [0:CYCLES-1];
    reg [ACC_W-1:0] expected_C [0:TOTAL_OUTPUTS-1];

    integer i;
    integer row;
    integer col;
    integer file_handle;
    integer mismatches;

    reg [ACC_W-1:0] actual_val;
    reg [ACC_W-1:0] expected_val;

    systolic_array_top #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .CLK(CLK),
        .RST(RST),
        .START(START),
        .A_in(A_in),
        .B_in(B_in),
        .acc_out(acc_out),
        .valid_out(valid_out),
        .DONE(DONE)
    );

    // Clock Generation (50 MHz)
    always #10 CLK = ~CLK;

    // Waveform Dump
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_systolic_array);
    end

    // Main Test Sequence
    initial begin
        mismatches = 0;
        // Load Python-Generated Test Vectors
        $readmemh("matrix_A.txt", stream_A);
        $readmemh("matrix_B.txt", stream_B);
        $readmemh("expected_C.txt", expected_C);

        // Initialize Signals
        CLK = 0;
        RST = 1;
        START = 0;
        A_in = 0;
        B_in = 0;
        // Reset DUT
        repeat (5) @(posedge CLK);
        #1;
        RST = 0;
        @(posedge CLK);
        #1;
        // Pulse START
        START = 1;
        @(posedge CLK);
        #1;
        START = 0;
        // Feed Matrix Streams
        $display("======================================================");
        $display("[TB INFO] Starting Matrix Stream Injection");
        $display("======================================================");

        for (i = 0; i < CYCLES; i = i + 1) begin
            A_in = stream_A[i];
            B_in = stream_B[i];
            $display("[STREAM] Cycle %0d/%0d", i, CYCLES-1);
            @(posedge CLK);
            #1;
        end

        // Stop Driving Inputs
        A_in = 0;
        B_in = 0;

        // Wait for DONE with Timeout Protection
        $display("[TB INFO] Waiting for DONE...");
        begin : timeout_guard
            fork
                // Thread 1 : Wait for DONE
                begin
                    while (!DONE)
                        @(posedge CLK);
                    $display("[TB INFO] DONE asserted.");
                    disable timeout_guard;
                end
                // Thread 2 : Timeout
                begin
                    repeat (100)
                        @(posedge CLK);
                    $display("[TIMEOUT ERROR] DONE never asserted.");
                    $finish;
                end
            join
        end
        // Allow Registered Outputs to Settle
        @(posedge CLK);
        #1;
        // Open Output File
        file_handle = $fopen("hardware_output.txt", "w");
        if (file_handle == 0) begin
            $display("[ERROR] Failed to open hardware_output.txt");
            $finish;
        end
      
        // Compare Against Golden Model
  
        $display("[TB INFO] Comparing Hardware Results");
        $display("======================================================");

        for (row = 0; row < N; row = row + 1) begin
            for (col = 0; col < N; col = col + 1) begin
                actual_val = acc_out[(row*N + col)*ACC_W +: ACC_W];
                expected_val = expected_C[row*N + col];
                
                $fdisplay(file_handle,"%04X",actual_val);
                
                if (actual_val !== expected_val) begin
                    $display(
                        "[FAIL] C[%0d][%0d]  HW=%04X  EXP=%04X",
                        row,
                        col,
                        actual_val,
                        expected_val
                    );
                    mismatches = mismatches + 1;
                end
            end
        end
        $fclose(file_handle);

        // Final Summary
        $display("======================================================");
        if (mismatches == 0)
            $display("[SUCCESS] All %0d outputs matched.", TOTAL_OUTPUTS);
        else
            $display("[FAILURE] %0d mismatches detected.", mismatches);
        $display("[TB INFO] Simulation complete.");
        $display("[TB INFO] Waveform: waveform.vcd");
        $display("[TB INFO] Hardware output: hardware_output.txt");
        $display("======================================================");
        $finish;
    end
endmodule
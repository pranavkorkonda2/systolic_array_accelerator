`timescale 1ns / 1ps

module tb_systolic_compute_mesh();

// parameters as Signals
    parameter N = 4;
    parameter DATA_W = 8;
    parameter ACC_W = 16;

    reg CLK;
    reg RST;
    reg [N-1:0] valid_in;
    reg [N*DATA_W-1:0] A_in;
    reg [N*DATA_W-1:0] B_in;
    
    wire [N*DATA_W-1:0] A_out;
    wire [N*DATA_W-1:0] B_out;
    wire [N*ACC_W-1:0] acc_out;
    wire [N-1:0] valid_out;

    // next, DUT initiation.
    systolic_compute_mesh #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .CLK(CLK),
        .RST(RST),
        .valid_in(valid_in),
        .A_in(A_in),
        .B_in(B_in),
        .A_out(A_out),
        .B_out(B_out),
        .acc_out(acc_out),
        .valid_out(valid_out)
    );

    // Clock Generation (50MHz -> 20ns period)
    always @(posedge CLK) begin
    // test simulation pipeline
        // Initialize Inputs
        CLK = 0;
        RST = 1;
        valid_in = 4'b0000;
        A_in = 32'h00000000;
        B_in = 32'h00000000;

        // Hold Reset for 2 clock cycles
        repeat(2) @(posedge CLK);
        #1; 
        RST = 0;
        
        @(posedge CLK);
        #1;

        // Cycle 0:
        // Row 0 gets its 1st element, Col 0 gets its 1st element. 
        // Other rows/cols are inactive (skewed for now
        valid_in = 4'b0001; 
        A_in = {8'h00, 8'h00, 8'h00, 8'h02}; // A[0][0]=2
        B_in = {8'h00, 8'h00, 8'h00, 8'h03}; // B[0][0]=3
        
        @(posedge CLK); #1;

        // CYCLE 1:
        // Row 0  now gets its 2nd element.
        // Row 1 starts and gets its 1st element. others remained skewed
        valid_in = 4'b0011; 
        A_in = {8'h00, 8'h00, 8'h04, 8'h01}; // A[1][0]=4, A[0][1]=1
        B_in = {8'h00, 8'h00, 8'h05, 8'h01}; // B[0][1]=5, B[1][0]=1
        
        @(posedge CLK); #1;

        // CYCLE 2:
        // Clear inputs back to 0
        valid_in = 4'b0000;
        A_in = 32'h00000000;
        B_in = 32'h00000000;

        // Allow the data pipelines to completely drain through the mesh
        repeat(10) @(posedge CLK);

        // Display results of the top-left accumulation corner PE(0,0)
        // Expected PE(0,0) calculation: (2 * 3) + (1 * 1) = 6 + 1 = 7
        $display("[SIMULATION LOG] PE(0,0) Accumulator Output = %d (Expected: 7)", acc_out[15:0]);
        
        if (acc_out[15:0] == 16'd7)
            $display("SUCCESS: Milestone 2 Mesh Interconnect Works!");
        else
            $display("ERROR: Output Mismatch. Check your wire assignments.");

        $finish;
    end

endmodule
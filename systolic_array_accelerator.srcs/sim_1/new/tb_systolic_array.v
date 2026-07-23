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
    parameter ACC_W = 16;
    parameter CYCLES = 2 * N - 1;
    
    reg CLK;
    reg RST;
    reg START;
    
    reg [N*DATA_W-1:0] A_in;
    reg [N*DATA_W-1:0] B_in;
    wire [N*N*ACC_W-1:0] acc_out;
    wire [N-1:0] valid_out;
    wire DONE;
    
    reg [N*DATA_W-1:0] stream_A [0:CYCLES-1];
    reg [N*DATA_W-1:0] stream_B [0:CYCLES-1];
    
    integer i, row, col, file_handle;
    systolic_array_top #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W))
        dut (
            .CLK(CLK),
            .RST(RST),
            .START(START),
            .A_in(A_in),
            .B_in(B_in),
            .acc_out(acc_out),
            .valid_out(valid_out),
            .DONE(DONE)
            );
    // 50 MHz clock gen, 20 ns period
    always #10 CLK = ~CLK;
    initial begin 
        $readmemh("matrix_A.txt", stream_A);
        $readmemh("matrix_B.txt", stream_B);
        
        CLK = 0;
        RST = 1;
        START = 0;
        A_in = 0;
        B_in = 0;
        
        repeat(2) @(posedge CLK); #1;
        RST = 0;
        repeat(1) @(posedge CLK); #1;
        START = 1;
        @(posedge CLK); #1; START = 0;
        
        // feed stream data every clock cycle during execution
        $display("[TB INFO] Beginning Matrix Data Injection...");
        for (i = 0; i < CYCLES; i = i + 1) begin
            A_in = stream_A[i];
            B_in = stream_B[i];
            @(posedge CLK); #1;
        end
        // clear inputs
        A_in = 0;
        B_in = 0;
        
        $display("[TB INFO] Waiting for Controller DONE signal...");
        while (!DONE) begin
            @(posedge CLK);
        end
        
        file_handle = $fopen("hardware_output.txt", "w");
        
        for (row = 0; row < N; row = row + 1) begin
            for (col = 0; col < N; col = col + 1) begin
                $fdisplay(file_handle, "%04X", acc_out[(row*N + col) * ACC_W +: ACC_W]);
            end
        end
        $fclose(file_handle);
        $display("[TB INFO] Hardware calculations saved to 'hardware_output.txt'. Simulation finished!");
        $finish;
   end
    
endmodule

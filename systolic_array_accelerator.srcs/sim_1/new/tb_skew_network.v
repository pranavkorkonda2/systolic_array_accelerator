`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2026 03:35:49 AM
// Design Name: 
// Module Name: tb_skew_network
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
module tb_skew_network;
parameter N = 4;
parameter DATA_W = 8;

reg CLK;
reg RST;
reg [N-1:0] valid_in;
reg [N*DATA_W-1:0] A_in;
reg [N*DATA_W-1:0] B_in;

wire [N-1:0] skewed_valid_out;
wire [N*DATA_W-1:0] skewed_A_out;
wire [N*DATA_W-1:0] skewed_B_out;

input_skew_network #(
    .N(N),
    .DATA_W(DATA_W)) 
    
    dut (
        .CLK(CLK),
        .RST(RST),
        .valid_in(valid_in),
        .A_in(A_in),
        .B_in(B_in),
        .skewed_valid_out(skewed_valid_out),
        .skewed_A_out(skewed_A_out),
        .skewed_B_out(skewed_B_out)
    );
always #10 CLK = ~CLK;

initial begin
        // Set all inputs to initial state
  CLK = 0;
  RST = 1;
  valid_in = 0;
  A_in = 0;
  B_in = 0;
        
  // Hold reset for 2 full clock cycles to clear internal skewer pipelines
  repeat(2) @(posedge CLK);
    #1; // Step slightly past the rising edge to avoid race conditions
    RST = 0;
  repeat(1) @(posedge CLK);
    // TEST CASE: Inject data to all channels simultaneously. 
    // Row/Col 0 should pass instantly, and then  Row/Col 3 should take 3 cycles.
       
    $display("[TB INFO] Injecting uniform parallel matrix waves at Cycle 0...");
    valid_in = 4'b1111; // Assert valid for all 4 rows
    // Pack data into 1D arrays: A_in = {Row3, Row2, Row1, Row0}
    A_in = {8'hDD, 8'hCC, 8'hBB, 8'hAA}; 
    B_in = {8'h44, 8'h33, 8'h22, 8'h11};

    @(posedge CLK);
        #1;
       
        // Turn off inputs on the next cycle, that way we can
        // see the data packets move
        valid_in = 4'b0000;
        A_in = 0;
        B_in = 0;

        // Cycle 0: both row and col 0 should appear immediately (bypass)
        if (skewed_A_out[7:0] == 8'hAA && skewed_B_out[7:0] == 8'h11 && skewed_valid_out[0] == 1'b1) begin
            $display("[PASS] Cycle 0: Row 0 and Col 0 matched instantly.");
        end else begin
            $display("[FAIL] Cycle 0: Channel 0 bypass error! Got A=%h, B=%h, V=%b", skewed_A_out[7:0], skewed_B_out[7:0], skewed_valid_out[0]);
        end

        repeat(1) @(posedge CLK);
        #1;
        // Cycle 1: both row 1 and col 1 should exit here after a single 
        // pipeline stage delay
        if (skewed_A_out[15:8] == 8'hBB && skewed_B_out[15:8] == 8'h22 && skewed_valid_out[1] == 1'b1) begin
            $display("[PASS] Cycle 1: Row 1 and Col 1 delayed by exactly 1 cycle.");
        end else begin
            $display("[FAIL] Cycle 1: Channel 1 skew error! Got A=%h, B=%h, V=%b", skewed_A_out[15:8], skewed_B_out[15:8], skewed_valid_out[1]);
        end

        repeat(1) @(posedge CLK);
        #1;
        
        // Cycle 2: row 2 and col 2 should exit here after 2 pipeline stages
        if (skewed_A_out[23:16] == 8'hCC && skewed_B_out[23:16] == 8'h33 && skewed_valid_out[2] == 1'b1) begin
            $display("[PASS] Cycle 2: Row 2 and Col 2 delayed by exactly 2 cycles.");
        end else begin
            $display("[FAIL] Cycle 2: Channel 2 skew error! Got A=%h, B=%h, V=%b", skewed_A_out[23:16], skewed_B_out[23:16], skewed_valid_out[2]);
        end

        repeat(1) @(posedge CLK);
        #1;
        // Cycle 3: row/col 3 should exit after 3 pipeline stages
        if (skewed_A_out[31:24] == 8'hDD && skewed_B_out[31:24] == 8'h44 && skewed_valid_out[3] == 1'b1) begin
            $display("[PASS] Cycle 3: Row 3 and Col 3 delayed by exactly 3 cycles.");
            $display("[SUCCESS] ALL SKEW CHANNELS CORRECTLY ALIGNED IN SPACE AND TIME!");
        end else begin
            $display("[FAIL] Cycle 3: Channel 3 skew error! Got A=%h, B=%h, V=%b", skewed_A_out[31:24], skewed_B_out[31:24], skewed_valid_out[3]);
        end

        repeat(2) @(posedge CLK);
        $finish;
    end

endmodule

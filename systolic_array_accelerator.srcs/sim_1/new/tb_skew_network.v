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
endmodule

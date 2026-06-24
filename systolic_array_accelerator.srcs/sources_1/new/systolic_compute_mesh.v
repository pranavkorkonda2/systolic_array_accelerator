`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2026 11:23:45 PM
// Design Name: 
// Module Name: systolic_compute_mesh
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Parameterized N x N Systolic Array for INT8 Matrix Mult
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module systolic_compute_mesh #(
parameter N = 4,
parameter DATA_W = 8,
parameter ACC_W = 16
)(
input wire CLK,
input wire RST,
input wire [N-1:0] valid_in, // This is our valid signals for rows/col
input wire [N*DATA_W-1:0] A_in, // N element left boundary input
input wire [N*DATA_W-1:0] B_in, // N element top boundary input

output wire [N*DATA_W-1:0] A_out,
output wire [N*DATA_W-1:0] B_out,
output wire [N*ACC_W-1:0] acc_out,
output wire [N-1:0] valid_out
);
endmodule

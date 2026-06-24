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
// internal interconnect wires
//  so, adding +1 to the dimensions allows easy boundary assignment
wire [DATA_W-1:0] A_w [0:N-1][0:N];
wire [DATA_W-1:0] B_w [0:N][0:N-1];
wire [ACC_W-1:0] acc_w [0:N-1][0:N-1];
wire valid_w [0:N-1][0:N-1];
// boundary conditions: map top-level inputs/outputs to wire the arrays

genvar row, col;
generate
for (row = 0; row < N; row = row + 1) begin: map_row_inputs_to_mesh
    assign A_w[row][0] = A_in[row*DATA_W +: DATA_W];
    assign A_out[row*DATA_W +: DATA_W] = A_w[row][N];
end
for (col = 0; col < N; col = col + 1) begin: map_col_inputs_to_mesh
    assign B_w[0][col] = B_in[col*DATA_W +: DATA_W];
    assign B_out[col*DATA_W +: DATA_W] = B_w[N][col];
end
endgenerate

// 2D mesh hardware generation
generate
    for (row = 0;  row < N; row = row + 1) begin: gen_row
        for (col = 0; col < N; col = col + 1) begin: gen_col
            systolic_mac_pe #(
                 .DATA_W(DATA_W),
                 .ACC_W(ACC_W)
                 )
            u_pe (
                  .CLK(CLK),
                  .RST(RST),
                  .A_in(A_w[row][col]),
                  .B_in(B_w[row][col]),
                  .valid_in(valid_in[row]),
                  .A_out(A_w[row][col+1]),   // Forward right
                  .B_out(B_w[row+1][col]),   // Forward down
                  .acc_out(acc_w[row][col]),
                  .valid_out(valid_w[row][col])
                  );
        end
    end
endgenerate

generate
    for (row = 0; row < N; row = row + 1) begin: flatten_outputs
        assign acc_out[row*ACC_W +: ACC_W] = acc_w[row][N-1];
        assign valid_out[row] = valid_w[row][N-1];
    end
endgenerate
endmodule

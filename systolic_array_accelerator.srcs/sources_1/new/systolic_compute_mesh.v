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
input wire [N-1:0] valid_in,
input wire [N*DATA_W-1:0] A_in,
input wire [N*DATA_W-1:0] B_in,

output wire [N*DATA_W-1:0] A_out,
output wire [N*DATA_W-1:0] B_out,
output wire [N*N*ACC_W-1:0] acc_out,
output wire [N-1:0] valid_out
);

// Internal interconnect wires
wire [DATA_W-1:0] A_w [0:N-1][0:N];
wire [DATA_W-1:0] B_w [0:N][0:N-1];
wire [ACC_W-1:0] acc_w [0:N-1][0:N-1];

// N+1 columns because each PE forwards valid to the next PE
wire valid_w [0:N-1][0:N];

genvar row, col;
generate
// Left boundary inputs and right boundary outputs
for (row = 0; row < N; row = row + 1) begin : map_row_inputs_to_mesh
    assign A_w[row][0] = A_in[row*DATA_W +: DATA_W];
    assign A_out[row*DATA_W +: DATA_W] = A_w[row][N];
end

// Top boundary inputs and bottom boundary outputs
for (col = 0; col < N; col = col + 1) begin : map_col_inputs_to_mesh
    assign B_w[0][col] = B_in[col*DATA_W +: DATA_W];
    assign B_out[col*DATA_W +: DATA_W] = B_w[N][col];
end

// Valid enters on left edge and propagates through row
for (row = 0; row < N; row = row + 1) begin : map_valid_inputs_to_mesh
    assign valid_w[row][0] = valid_in[row];
end

endgenerate


// N x N processing element mesh

generate
    for (row = 0; row < N; row = row + 1) begin : gen_row
        for (col = 0; col < N; col = col + 1) begin : gen_col
            systolic_mac_pe #(
                .DATA_W(DATA_W),
                .ACC_W(ACC_W)
            )
            u_pe (
                .CLK(CLK),
                .RST(RST),
                
                .A_in(A_w[row][col]),
                .B_in(B_w[row][col]),
                .valid_in(valid_w[row][col]),
                
                .A_out(A_w[row][col+1]),
                .B_out(B_w[row+1][col]),
                .acc_out(acc_w[row][col]),
                .valid_out(valid_w[row][col+1])
            );

        end
    end
endgenerate


// output flattening. data is taken from the 2D mesh and then packed into a single
// flat 1D output so it can leave the chip
generate
    for (row = 0; row < N; row = row + 1) begin : flatten_rows
        for (col = 0; col < N; col = col + 1) begin : flatten_cols
            assign acc_out[(row*N + col)*ACC_W +: ACC_W] = acc_w[row][col];
        end
    end
    
    for (row = 0; row < N; row = row + 1) begin : flatten_valids
        assign valid_out[row] = valid_w[row][N];
    end
endgenerate

endmodule

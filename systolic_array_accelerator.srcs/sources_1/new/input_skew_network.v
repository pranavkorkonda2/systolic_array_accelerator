`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2026 06:59:57 AM
// Design Name: 
// Module Name: input_skew_network
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


module input_skew_network #(
parameter N = 4,
parameter DATA_W = 8)(

input wire CLK,
input wire RST,
input wire [N-1:0] valid_in,
input wire [N*DATA_W-1:0] A_in,
input wire [N*DATA_W-1:0] B_in,
// Skewed outputs ready to drive the systolic compute mesh directly.

output wire [N-1:0] skewed_valid_out,
output wire [N*DATA_W-1:0] skewed_A_out,
output wire [N*DATA_W-1:0] skewed_B_out
);

genvar i, j;
// i is the # of cycles that matrix A is skewed by
// so, each row  is delayed by 'i' cycles.
// Data and valid flags must perfectly be bound together.
// similarly, matrix B is skewed by 'j' cycles.

generate
    for (i = 0; i < N; i = i + 1) begin: skew_A
    // Pack: Bit [DATA_W] = valid, Bits [DATA_W-1:0] = A data
        wire [DATA_W:0] pack_A_in = {valid_in[i], A_in[i*DATA_W +: DATA_W]};
        wire [DATA_W:0] pack_A_out;
        
        skewer_buffer #(
            .DATA_W(DATA_W + 1),
            .DEPTH(i)
            ) delay_A (
            .CLK(CLK),
            .RST(RST),
            .data_in(pack_A_in),
            .data_out(pack_A_out)
            );
            
            assign skewed_A_out[i*DATA_W +: DATA_W] = pack_A_out[DATA_W-1:0];
            assign skewed_valid_out = pack_A_out[DATA_W];
   end
endgenerate

generate
    for (j = 0; i < N; j = j + 1) begin: skew_B
    // Pack: Bit [DATA_W] = valid, Bits [DATA_W-1:0] = A data
        wire [DATA_W:0] raw_B_in = {valid_in[j], B_in[j*DATA_W +: DATA_W]};
        wire [DATA_W:0] skewed_B;
        
        skewer_buffer #(
            .DATA_W(DATA_W + 1),
            .DEPTH(j)
            ) delay_B (
            .CLK(CLK),
            .RST(RST),
            .data_in(pack_B_in),
            .data_out(skewed_B)
            );
            
            assign skewed_B_out[j*DATA_W +: DATA_W] = skewed_B;
   end
endgenerate

endmodule

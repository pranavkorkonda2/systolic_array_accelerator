`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2026 09:45:56 PM
// Design Name: 
// Module Name: systolic_array_top
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
module systolic_array_top #(
    parameter N = 4,
    parameter DATA_W = 8,
    parameter ACC_W = 16
)(
    input wire CLK,
    input wire RST,
    input wire START,
    input wire [N*DATA_W-1:0] A_in,
    input wire [N*DATA_W-1:0] B_in,
    
    output wire [N*N*ACC_W-1:0] acc_out,
    output wire [N-1:0] valid_out,
    output wire DONE
);

    // 1. Internal Interconnect Wires
    wire CLEAR_ACC;
    wire MESH_VALID_IN;
    wire [N-1:0] fsm_valid_vector;
    wire mesh_rst;

    // Controller FSM
    controller_fsm #(.N(N)) u_controller (
        .CLK(CLK),
        .RST(RST),
        .START(START),
        .CLEAR_ACC(CLEAR_ACC),
        .MESH_VALID_IN(MESH_VALID_IN),
        .DONE(DONE)
    );

    // Instantiate Systolic Compute Mesh
    systolic_compute_mesh #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) u_compute_mesh (
        .CLK(CLK),
        .RST(mesh_rst),
        .valid_in(fsm_valid_vector), // Direct from FSM!
        .A_in(A_in),                 // Pre-skewed from TB!
        .B_in(B_in),                 // Pre-skewed from TB!
        .A_out(),
        .B_out(),
        .acc_out(acc_out),
        .valid_out(valid_out)
    );

    // MESH_VALID_IN is driven only when Row 0 data actually enters
    assign fsm_valid_vector = {N{MESH_VALID_IN}};

    // Resets accumulators when reset or clear is requested
    assign mesh_rst = RST | CLEAR_ACC;

endmodule
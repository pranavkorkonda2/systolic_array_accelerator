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
    
    output wire [N*ACC_W-1:0] acc_out,
    output wire [N-1:0] valid_out,
    output wire DONE
);

    // 1. Internal Interconnect Wires
    wire CLEAR_ACC;
    wire MESH_VALID_IN;
    
    wire [N-1:0] fsm_valid_vector;
    wire [N-1:0] skewed_valid;
    wire [N*DATA_W-1:0] skewed_A;
    wire [N*DATA_W-1:0] skewed_B;
    
    wire mesh_rst;

    // 2. Module Instantiations
    
    // Controller FSM
    controller_fsm #(.N(N)) u_controller (
        .CLK(CLK),
        .RST(RST),
        .START(START),
        .CLEAR_ACC(CLEAR_ACC),
        .MESH_VALID_IN(MESH_VALID_IN),
        .DONE(DONE)
    );

    // Input Skew Network
    input_skew_network #(
        .N(N),
        .DATA_W(DATA_W)
    ) u_skew_network (
        .CLK(CLK),
        .RST(RST),
        .valid_in(fsm_valid_vector),
        .A_in(A_in),
        .B_in(B_in),
        .skewed_valid_out(skewed_valid),
        .skewed_A_out(skewed_A),
        .skewed_B_out(skewed_B)
    );

    // Systolic Compute Mesh
    systolic_compute_mesh #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) u_compute_mesh (
        .CLK(CLK),
        .RST(mesh_rst),
        .valid_in(skewed_valid),
        .A_in(skewed_A),
        .B_in(skewed_B),
        .A_out(),      // Left floating: Data exits the right boundary of the chip 
        .B_out(),      // Left floating: Data exits the bottom boundary of the chip
        .acc_out(acc_out),
        .valid_out(valid_out)
    );
    
    // The FSM outputs a single 'MESH_VALID_IN' bit. 
    // We replicate it N times so that all N rows/columns get the valid flag simultaneously.
    assign fsm_valid_vector = {N{MESH_VALID_IN}};

    // The compute mesh needs to clear its internal accumulators during STATE_LOAD.
    // We achieve this by ORing the global system 'RST' with the FSM's 'CLEAR_ACC' signal.
    assign mesh_rst = RST | CLEAR_ACC;

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Pranav Korkonda
// Engineer: 
// 
// Create Date: 06/16/2026 10:55:45 PM
// Design Name: 
// Module Name: systolic_mac_pe
// Project Name: Systolic Accelerator
// Target Devices: 
// Tool Versions: 
// Description: Parameterized INT8 Processing Element (PE) with registered 
//                  data-forwarding and an accumulation guard path
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module systolic_mac_pe #(parameter DATA_W = 8, parameter ACC_W = 16)(
    input CLK, RST, valid_in,
    input [DATA_W-1:0] A_in, B_in,
    
    output reg valid_out,
    output reg [DATA_W-1:0] A_out, B_out,
    output [ACC_W-1:0] acc_out // continuous wire
    );
    reg [ACC_W-1:0] acc_reg;
    assign acc_out = acc_reg;
    always @(posedge CLK) begin

    if (RST) begin // when RST is active high, everything is initialized
                   // to 0; local accumulation register is cleared   
        A_out     <= 0;
        B_out     <= 0;
        acc_reg   <= 0;
        valid_out <= 0;
    end else begin
        A_out <= A_in;
        B_out <= B_in;
        valid_out <= valid_in;
        // we must check if valid_in is active high so that
        // A_in and B_in are valid matrix data, which allows the PE
        // to perform a MAC operation (see below) and update the accumulator
        // if valid_in is OFF, A_in and B_in should be considered invalid or "DON'T CARE"
        // Then, the accumulator will NOT update, so no garbage values
        // are corrupting the result
        if (valid_in)
            acc_reg <= acc_reg + (A_in * B_in);
        // AI models use MULTIPLY ACCUMULATE (MAC):
        // 1. (A_in * B_in) multiplies an input data feature by its model weight
        // 2. sum it with the previous acc_reg, and this is essentially
        // summing the products in multiple cycles, which is fundamentally what
        // AI neurons use dot  products for
        
    end
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 10:55:45 PM
// Design Name: 
// Module Name: controller_fsm
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


module controller_fsm #(parameter N = 4)(
input wire CLK,
input wire RST,
input wire START, // host signal to begin matrix multiplication

output reg CLEAR_ACC, // signals PE to clear accumulation register
output reg MESH_VALID_IN, // controls the input data valid stream to the skew network
output reg DONE // flag to host execution is complete
);

localparam STATE_IDLE = 2'b00;
localparam STATE_LOAD = 2'b01;
localparam STATE_COMPUTE = 2'b10;
localparam STATE_OUTPUT_VALID = 2'b11;

reg current_state;
reg next_state;
// Execution Counter
// Tracks cycles during COMPUTE state. Needs to count up to (3N - 2).
// For N=4, 3(4)-2 = 10 cycles. A 4-bit counter is safe up to 15.
reg[3:0] cycle_counter;
wire counter_flag = (cycle_counter == (3 * N - 2));

always @(posedge CLK) begin
    if (RST) begin
       current_state <= STATE_IDLE;
    end else begin
        current_state <= next_state;
    end
end
endmodule

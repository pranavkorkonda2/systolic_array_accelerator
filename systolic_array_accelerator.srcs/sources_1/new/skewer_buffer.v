`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 10:55:45 PM
// Design Name: 
// Module Name: skewer_buffer
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


module skewer_buffer #(
parameter DATA_W = 8,
parameter DEPTH = 0)(
input wire CLK,
input wire RST,
input wire [DATA_W-1:0] data_in,
output wire [DATA_W-1:0] data_out);

if (DEPTH == 0) begin: bypass
    assign data_out = data_in;
    // Literally, if the depth is 0, then this module will just be a 
    // Bypass wire. However, if depth > 0, then a true shift register chain
    // will be instantiated
end else begin: shift_reg
    reg [DATA_W-1:0] shift_pipeline [0:DEPTH-1];
    integer i;
    
    always @(posedge CLK) begin
    if (RST) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            shift_pipeline[i] <= 0;
            // cache cleared from pipelines
        end
    end else begin
        shift_pipeline[0] <= data_in;
        for (i = 1; i < DEPTH; i = i + 1) begin
            shift_pipeline[i] <= shift_pipeline[i - 1];
            // shifting data forward by one position on every clock cycle.
            // on rising edge of CLK, whatever value is currently sitting 
            // on the external data_in pin is captured and saved into 
            // the very first flip-flop stage: shift_pipeline[0].
        end
    end
end
assign data_out = shift_pipeline[DEPTH-1];
end
endmodule

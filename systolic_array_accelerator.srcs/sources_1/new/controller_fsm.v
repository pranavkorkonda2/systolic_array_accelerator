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

always @(posedge CLK) begin
    if (RST || current_state == STATE_IDLE) begin
        cycle_counter <= 0;
    end else if (current_state == STATE_COMPUTE) begin
        cycle_counter <= cycle_counter + 1;
    end
 end

always @(*) begin
    next_state = current_state;
    case (current_state)
        STATE_IDLE: begin
            if (START)
                next_state = STATE_LOAD;
            else
                next_state = STATE_IDLE;
        end
        STATE_LOAD: begin
            next_state = STATE_COMPUTE;
        end
        STATE_COMPUTE: begin
            if (counter_flag)
                next_state = STATE_OUTPUT_VALID;
            else
                next_state = STATE_COMPUTE;
        end
        STATE_OUTPUT_VALID: begin
            next_state = STATE_IDLE;
        end
        default: next_state = STATE_IDLE;
    endcase
end

always @(*) begin
        // Safe default assignments to guarantee pure combinational logic
    CLEAR_ACC = 1'b0;
    MESH_VALID_IN = 1'b0;
    DONE = 1'b0;
    case (current_state)
         STATE_IDLE: begin
                // Keep everything squashed to minimize dynamic power draw
         end 
         STATE_LOAD: begin
                // Flush out any stale matrix data from the PE accumulators
            CLEAR_ACC = 1'b1;
            end
         STATE_COMPUTE: begin
                // Keep feeding real data valid tokens through the network
            MESH_VALID_IN = 1'b1;
         end
         STATE_OUTPUT_VALID: begin
                // Signal the external CPU to safely latch the completed calculations
            DONE = 1'b1;
         end
    endcase
end

endmodule

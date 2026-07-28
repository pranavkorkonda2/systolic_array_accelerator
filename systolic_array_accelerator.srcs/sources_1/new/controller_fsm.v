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
    input wire START,

    output reg CLEAR_ACC,
    output reg MESH_VALID_IN,
    output reg DONE
);

    localparam STATE_IDLE         = 2'b00;
    localparam STATE_CLEAR        = 2'b01;
    localparam STATE_COMPUTE      = 2'b10;
    localparam STATE_OUTPUT_VALID = 2'b11;

    reg [1:0] current_state, next_state;
    reg [4:0] cycle_counter;
    
    // Total execution cycles required: 
    // Stream depth (2*N - 1) + Array depth (N - 1) = 3*N - 2 cycles (10 cycles for N=4)
    // Counting 0 to 10 is 11 clock cycles.
    wire counter_flag = (cycle_counter == (3 * N - 1));

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

    // Next State Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                if (START)
                    next_state = STATE_CLEAR; // Step 1: Go to CLEAR first!
                else
                    next_state = STATE_IDLE;
            end
            
            STATE_CLEAR: begin
                // Step 2: Automatically move to COMPUTE on the next cycle
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

    // Combinational Output Logic
    always @(*) begin
        CLEAR_ACC     = 1'b0;
        MESH_VALID_IN = 1'b0;
        DONE          = 1'b0;
        
        case (current_state)
            STATE_IDLE: begin
                // Do nothing, wait for START
            end
            
            STATE_CLEAR: begin
                // Synchronously clear accumulators 1 cycle BEFORE computation starts
                CLEAR_ACC = 1'b1; 
            end
            
            STATE_COMPUTE: begin
                // Accumulators are clean, enable computation
                MESH_VALID_IN = 1'b1; 
            end
            
            STATE_OUTPUT_VALID: begin
                DONE = 1'b1;
            end
        endcase
    end
endmodule
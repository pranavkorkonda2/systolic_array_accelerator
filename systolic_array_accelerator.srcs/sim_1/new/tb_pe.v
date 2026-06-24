`timescale 1ns / 1ps
// =============================================================================
// Author:          Pranav Korkonda
// Create Date:     06/16/2026
// Module Name:     tb_pe
// Project Name:    Systolic Accelerator Verification
// Description:     Self-checking behavioral testbench for the foundational 
//                  Systolic Processing Element (PE).
// =============================================================================

module tb_pe;

    // 1. Declare local parameters to feed into our DUT
    parameter DATA_W = 8;
    parameter ACC_W = 16;
    
    // 2. Declare local registers (Inputs to DUT) and wires (Outputs from DUT)
    reg CLK_tb;
    reg RST_tb;
    reg valid_in_tb;
    reg [DATA_W-1:0] A_in_tb;
    reg [DATA_W-1:0] B_in_tb;

    wire valid_out_tb;
    wire [DATA_W-1:0] A_out_tb;
    wire [DATA_W-1:0] B_out_tb;
    wire [ACC_W-1:0] acc_out_tb;

    // 3. Instantiate the DUT, which is "plugging the chip into the socket"
    systolic_mac_pe #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .CLK(CLK_tb),
        .RST(RST_tb),
        .valid_in(valid_in_tb),
        .A_in(A_in_tb),
        .B_in(B_in_tb),
        .valid_out(valid_out_tb),
        .A_out(A_out_tb),
        .B_out(B_out_tb),
        .acc_out(acc_out_tb)
    );

    // 4. Clock Generation: this generates a constant clock cycle which has a period of 20 ns
    // (f = 50 MHz)
    always begin
        CLK_tb = 0;
        #10; // wait 10ns
        CLK_tb = 1;
        #10; // wait 10ns
    end

    // 5. Testing our matrix math...
    initial begin
        // Initialize our input lines to an idle state
        RST_tb = 0;
        valid_in_tb = 0;
        A_in_tb = 0;
        B_in_tb = 0;
        #20; // wait 1 full clock cycle

        // Trigger System Reset
        RST_tb = 1;
        #20; // Hold reset active for 1 cycle
        RST_tb = 0;
        #10; // Align data setup to the falling edge of clock for stable simulation

        // Now, test calculation 1 (X1 * W1 = 3 * 4 = 12)
        valid_in_tb = 1;
        A_in_tb = 8'd3;
        B_in_tb = 8'd4;
        #20; // Hold for 1 clock cycle

        // Test Calculation 2 (X2 * W3 = 2 * 5 = 10)
        // The accumulator should calculate: 12 + 10 = 22
        A_in_tb = 8'd2;
        B_in_tb = 8'd5;
        
        // Check if the previous cycle's data successfully traveled through the PE registers
        if (A_out_tb != 8'd3)       $display("PIPELINE ERROR: FAIL A_out! Expected 3, got %d", A_out_tb);
        if (B_out_tb != 8'd4)       $display("PIPELINE ERROR: FAIL B_out! Expected 4, got %d", B_out_tb);
        if (valid_out_tb != 1'b1)   $display("PIPELINE ERROR: FAIL valid_out! Expected 1, got %b", valid_out_tb);
        #20; // Hold for 1 clock cycle

        // turn off valid_in (No more matrix data flowing from this point on)
        valid_in_tb = 0;
        A_in_tb = 8'd42; // Feed in junk values to test if our gate blocks them
        B_in_tb = 8'd99;
        #20;
        
        // VERIFICATION for our hardware matching the expected linear algebra value (22)
        if (acc_out_tb == 16'd22) begin
            $display("TESTBENCH PASS: Accumulator correctly holds 22!");
        end else begin
            $display("TESTBENCH FAIL: Expected 22, instead got: %d", acc_out_tb);
        end
        // finish simulation
        $finish;
    end

endmodule
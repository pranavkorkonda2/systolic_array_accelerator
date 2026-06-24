`timescale 1ns / 1ps

module tb_systolic_compute_mesh;

parameter N      = 4;
parameter DATA_W = 8;
parameter ACC_W  = 16;

reg CLK;
reg RST;
reg [N-1:0] valid_in;
reg [N*DATA_W-1:0] A_in;
reg [N*DATA_W-1:0] B_in;

wire [N*DATA_W-1:0] A_out;
wire [N*DATA_W-1:0] B_out;
wire [N*ACC_W-1:0] acc_out;
wire [N-1:0] valid_out;

systolic_compute_mesh #(
    .N(N),
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
) dut (
    .CLK(CLK),
    .RST(RST),
    .valid_in(valid_in),
    .A_in(A_in),
    .B_in(B_in),
    .A_out(A_out),
    .B_out(B_out),
    .acc_out(acc_out),
    .valid_out(valid_out)
);

// 50 MHz clock
always #10 CLK = ~CLK;

initial begin

    // Initialization
    CLK      = 0;
    RST      = 1;
    valid_in = 0;
    A_in     = 0;
    B_in     = 0;

    // Hold reset
    repeat(2) @(posedge CLK);

    RST = 0;

    // Inject one data packet
    @(posedge CLK);

    valid_in = 4'b0001;

    // Row 0 receives A=2
    A_in = {8'd0,8'd0,8'd0,8'd2};

    // Col 0 receives B=3
    B_in = {8'd0,8'd0,8'd0,8'd3};

    @(posedge CLK);

    // Remove inputs
    valid_in = 0;
    A_in = 0;
    B_in = 0;

    // Allow propagation
    repeat(6) @(posedge CLK);

    // Observe outputs
    $display("--------------------------------");
    $display("A_out = %h", A_out);
    $display("B_out = %h", B_out);
    $display("acc_out = %h", acc_out);
    $display("--------------------------------");

    // Rightmost PE of row 0 should
    // eventually have accumulated:
    // 2 * 3 = 6
    if(acc_out[15:0] == 16'd6)
        $display("PASS");
    else
        $display("FAIL: Expected 6, Got %d", acc_out[15:0]);

    $finish;

end

endmodule

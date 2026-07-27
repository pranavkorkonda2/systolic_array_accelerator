################################################################################
# Generic I/O timing assumptions
# These delays model an external device with approximately 2 ns setup/hold
# requirements. They are used for timing analysis only.
################################################################################
################################################################################
# Clock Constraint
# Defines a 100 MHz clock (10.0 ns period) with a 50% duty cycle on signal 'CLK'
################################################################################
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports CLK]

################################################################################
# Virtual / Input and Output Delay Constraints
# Constrains I/O paths relative to the clock for baseline timing closure
################################################################################
set_input_delay -clock [get_clocks sys_clk] 2.000 [get_ports {START A_in[*] B_in[*]}]
set_output_delay -clock [get_clocks sys_clk] 2.000 [get_ports {acc_out[*] valid_out[*] DONE}]
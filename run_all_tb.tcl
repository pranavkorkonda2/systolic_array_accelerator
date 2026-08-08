# Dynamically find the path of this script and set working directory
set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

# Open Vivado project if not already open
if {[catch {current_project}]} {
    open_project systolic_array_accelerator.xpr
}

# Define testbenches to execute sequentially
set testbenches {tb_pe tb_skew_network tb_compute_mesh tb_systolic_array}

foreach tb $testbenches {
    puts "\n=================================================="
    puts " RUNNING TESTBENCH: $tb"
    puts "==================================================\n"
    set_property top $tb [get_filesets sim_1]
    
    # Close any active simulation to release file locks on log files
    if {[get_sim_sets sim_1] ne "" && [current_sim] ne ""} {
        close_sim -force
    }
    
    launch_simulation
}

close_project
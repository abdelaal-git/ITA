### 

## MASTER CLOCKS
create_clock -name clk -period 25 [get_ports {clk_i}] 

set_clock_uncertainty 0.5 [get_clocks {clk}] 

set_propagated_clock [get_clocks {clk}]

## INPUT/OUTPUT DELAYS
set input_delay_value 4
set output_delay_value 10

# set_input_delay $input_delay_value  -clock [get_clocks {clk}] -add_delay [all_inputs]
# set_input_delay 0  -clock [get_clocks {clk}] [get_ports {clk_i}]
set_output_delay $output_delay_value -clock [get_clocks {clk}] [all_outputs]

## MAX FANOUT
set_max_fanout 12 [current_design]

## FALSE PATHS (ASYNCHRONOUS INPUTS)
set_false_path -from [get_ports {rst_ni}] -to [get_clocks {clk}]
set_false_path -from [get_ports {rst_ni}] -to [get_clocks {clk}] -through [get_nets {rst_ni}]

# add loads for output ports (pads)
set min_cap 0.5
set max_cap 1.0

set_load -min $min_cap [all_outputs] 
set_load -max $max_cap [all_outputs] 

# transition times for input ports
set min_in_tran 1
set max_in_tran 1.49

set_input_transition -min $min_in_tran [all_inputs] 
set_input_transition -max $max_in_tran [all_inputs]

# derates
set derate 0.15

set_timing_derate -early [expr 1-$derate]
set_timing_derate -late [expr 1+$derate]

## MAX transition/cap
set_max_trans 0.9 [current_design]

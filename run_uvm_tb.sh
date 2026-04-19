#!/bin/bash

# Copyright 2024 ITA project.
# SPDX-License-Identifier: SHL-0.51

# UVM Testbench Run Script for ITA Design
# This script compiles and runs the UVM-based testbench for the ITA accelerator

# Set up environment
export MODELSIM_DIR="/path/to/modelsim"  # Update this path
export UVM_HOME="/path/to/uvm"          # Update this path

# Create work library
vlib work
vmap work work

# Compile UVM library (adjust path as needed)
vlog -sv $UVM_HOME/src/uvm_pkg.sv +incdir+$UVM_HOME/src

# Compile ITA package
vlog -sv src/ita_package.sv

# Compile ITA RTL modules
vlog -sv src/ita.sv
vlog -sv src/ita_controller.sv
vlog -sv src/ita_dotp.sv
vlog -sv src/ita_accumulator.sv
vlog -sv src/ita_activation.sv
vlog -sv src/ita_gelu.sv
vlog -sv src/ita_relu.sv
vlog -sv src/ita_softmax.sv
vlog -sv src/ita_softmax_top.sv
vlog -sv src/ita_serdiv.sv
vlog -sv src/ita_requantizer.sv
vlog -sv src/ita_requantization_controller.sv
vlog -sv src/ita_max_finder.sv
vlog -sv src/ita_sumdotp.sv
vlog -sv src/ita_input_sampler.sv
vlog -sv src/ita_output_controller.sv
vlog -sv src/ita_weight_controller.sv
vlog -sv src/ita_fifo_controller.sv
vlog -sv src/ita_inp1_mux.sv
vlog -sv src/ita_inp2_mux.sv
vlog -sv src/ita_register_file_1w_1r_double_width_write.sv
vlog -sv src/ita_register_file_1w_multi_port_read.sv
vlog -sv src/ita_register_file_1w_multi_port_read_we.sv

# Compile AXI memory model
vlog -sv src/tb/axi_memory.sv

# Compile UVM testbench
vlog -sv src/tb/ita_uvm_tb_top.sv

# Compile top-level testbench
vlog -sv src/tb/ita_uvm_tb_module.sv

# Run simulation
# Default test: ita_simple_test
# Other tests: ita_config_test, ita_memory_test
vsim -c ita_uvm_tb -do "run -all; quit"

echo "UVM testbench simulation completed."
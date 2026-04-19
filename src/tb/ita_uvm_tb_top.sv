#!/usr/bin/env bash
# Copyright 2024 ITA project.
# SPDX-License-Identifier: SHL-0.51

# UVM Testbench run script

# Set up environment
export UVM_HOME=/path/to/uvm # Update this path
export MODELSIM_PATH=/mnt/d/Programs/ModelSim/modelsim_ase/win32aloem

# Compile and run
vlog -sv +incdir+src/tb +incdir+src +define+UVM src/tb/ita_uvm_pkg.sv src/tb/ita_uvm_tb.sv src/ita.sv src/ita_ctrl_regs.sv src/ita_mem_master.sv src/tb/axi_memory.sv -L uvm_pkg
vsim -c ita_uvm_tb -do "run -all; quit"</content>
<parameter name="filePath">d:\MSc\Purdue\69500\Project\ITA\run_uvm_tb.sh
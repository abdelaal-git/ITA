# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.PHONY: lib build
all: lib build
MODELSIM_PATH = /mnt/d/Programs/ModelSim/modelsim_ase/win32aloem
VLOG = $(MODELSIM_PATH)/vlog.exe
VSIM = $(MODELSIM_PATH)/vsim.exe
VLIB = $(MODELSIM_PATH)/vlib.exe
VMAP = $(MODELSIM_PATH)/vmap.exe
buildpath   ?= build
VSIM_FLAGS  ?= ""
DEBUG       ?= ON

all: compile run wave
# ============================
# Ensure modelsim.ini exists
# ============================
modelsim_ini:
	cp /mnt/d/Programs/ModelSim/modelsim_ase/modelsim.ini $(buildpath)/modelsim.ini

lib: modelsim_ini
	cd $(buildpath) && $(VLIB) work && $(VMAP) work work

# ============================
# Compile only
# ============================
compile: lib
	cd $(buildpath) && $(VSIM) -c -do "source compile.tcl; quit"

# ============================
# Run simulation (no GUI)
# ============================
run:
	cd $(buildpath) && $(VSIM) $(VSIM_FLAGS) -c -do 'source ../sim_ita_tb.tcl'

# ============================
# Run simulation with GUI + waves
# ============================
wave:
	cd $(buildpath) && $(VSIM) $(VSIM_FLAGS) -gui -do "set DEBUG ON; source ../sim_ita_tb.tcl"

sim_ita_tb: lib compile
	cd $(buildpath) && $(VSIM) $(VSIM_FLAGS) -do 'source ../sim_ita_tb.tcl'

sim_ita_hwpe_tb: lib compile
	cd $(buildpath) && $(VSIM) $(VSIM_FLAGS) -do 'set DEBUG $(DEBUG); source ../sim_ita_hwpe_tb.tcl'

sim_activation_tb: lib compile
	cd $(buildpath) && $(VSIM) $(VSIM_FLAGS) -do 'source ../sim_activation_tb.tcl'

sim_uvm_tb: lib
	cd $(buildpath) && $(VLOG) -sv +incdir+../../src/tb +incdir+../../src +define+UVM ../../src/tb/ita_uvm_pkg.sv ../../src/tb/ita_uvm_test.sv ../../src/ita.sv ../../src/ita_ctrl_regs.sv ../../src/ita_mem_master.sv ../../src/tb/axi_memory.sv -L uvm_pkg && $(VSIM) -c ita_uvm_tb -do "run -all; quit"

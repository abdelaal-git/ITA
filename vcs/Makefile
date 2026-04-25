# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.PHONY: all compile run wave clean
all: compile run

# VCS Settings
unexport VCS_HOME
VCS_HOME       ?= /package/eda2/synopsys/vcs/X-2025.06-SP2-2/linux64
unexport VERDI_HOME
VERDI_HOME     ?= /package/eda2/synopsys/verdi/X-2025.06-SP2-2
VCS            = $(VCS_HOME)/bin/vcs
VERDI          = $(VERDI_HOME)/bin/verdi
VCS_SV_FLAGS   = -sverilog -timescale=1ns/1ps -vpi
VCS_COMPILE_LOG = vcs_compile.log

buildpath   ?= build
VCS_DEFINES ?=

# ============================
# Compile with VCS using Bender script
# ============================
compile:
	@echo "=== Compiling with VCS ==="
	@if [ ! -f $(buildpath)/compile.tcl ]; then \
		echo "Error: compile.tcl not found. Run 'make compile' from root Makefile first."; \
		exit 1; \
	fi
	cd $(buildpath) && $(VCS) $(VCS_SV_FLAGS) -o simv \
		-f ../compile.tcl \
		2>&1 | tee $(VCS_COMPILE_LOG)
	@echo "=== VCS Compilation complete ==="

# ============================
# Run simulation (no GUI)
# ============================
run:
	@echo "=== Running with VCS ==="
	cd $(buildpath) && ./simv -ucli -do "../sim_ita_tb.tcl"

# ============================
# Run simulation with GUI + waves
# ============================
wave:
	@echo "=== Running VCS with waves ==="
	cd $(buildpath) && DUMPFS=1 ./simv -ucli -do "../sim_ita_tb.tcl"

# ============================
# HWPE testbench targets
# ============================
compile_hwpe:
	@echo "=== Compiling HWPE testbench with VCS ==="
	@if [ ! -f $(buildpath)/compile.tcl ]; then \
		echo "Error: compile.tcl not found. Run 'make compile' from root Makefile first."; \
		exit 1; \
	fi
	cd $(buildpath) && $(VCS) $(VCS_SV_FLAGS) -o simv \
		-f ../compile.tcl \
		2>&1 | tee $(VCS_COMPILE_LOG)
	@echo "=== VCS HWPE Compilation complete ==="

run_hwpe:
	@echo "=== Running HWPE testbench with VCS ==="
	cd $(buildpath) && ./simv -ucli -do "../sim_ita_hwpe_tb.tcl"

wave_hwpe:
	@echo "=== Running HWPE testbench with waves ==="
	cd $(buildpath) && DUMPFS=1 ./simv -ucli -do "../sim_ita_hwpe_tb.tcl"

# ============================
# Verdi waveform viewer
# ============================
verdi:
	@echo "=== Opening Verdi waveform viewer ==="
	$(VERDI) -f ../compile.tcl -ssv -top ita_tb &

verdi_hwpe:
	@echo "=== Opening Verdi waveform viewer for HWPE ==="
	$(VERDI) -f ../compile.tcl -ssv -top ita_hwpe_tb &

# ============================
# Clean build artifacts
# ============================
clean:
	rm -rf $(buildpath)/simv*
	rm -rf $(buildpath)/AN.DB
	rm -rf $(buildpath)/csrc
	rm -rf $(buildpath)/*.log
	rm -rf $(buildpath)/inter.vpd
	rm -rf $(buildpath)/vc_hdrs.h
	rm -rf $(buildpath)/.vcs*
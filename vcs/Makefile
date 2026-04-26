# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.PHONY: all compile run wave clean dpi

all: dpi compile run

BENDER =$(BENDER_INSTALL_DIR)

# VCS Settings
VCS_HOME       := /package/eda2/synopsys/vcs/X-2025.06-SP2-2
UVM_HOME       := $(VCS_HOME)/etc/uvm
VERDI_HOME     := /package/eda2/synopsys/verdi/X-2025.06-SP2-2

VCS            := $(VCS_HOME)/linux64/bin/vcs
VERDI          := $(VERDI_HOME)/bin/verdi

# ============================
# DPI Settings (NEW)
# ============================
DPI_DIR        := ../PyITA
DPI_C          := $(DPI_DIR)/ita_dpi.c
DPI_SO         := $(DPI_DIR)/ita_dpi.so

# VCS Compile Flags
VCS_SV_FLAGS   = -sverilog -timescale=1ns/1ps -debug_access+all -full64 \
                 -top ita_uvm_tb uvm_dpi.o -kdb \
                 -sv_lib $(DPI_SO)          # ← Important: link your DPI library

VCS_ELAB_LOG   = vcs_elab.log
VCS_COMPILE_LOG= vcs_compile.log

buildpath ?= build
VCS_DEFINES ?=

# ============================
# Build DPI Shared Library (NEW TARGET)
# ============================
dpi:
	@echo "=== Building ITA DPI shared library ==="
	cd $(DPI_DIR) && \
	gcc -shared -fPIC -o ita_dpi.so ita_dpi.c \
		$(shell python3-config --includes) \
		-DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION \
		-I$(VCS_HOME)/include
	@echo "DPI library built: $(DPI_SO)"

# ============================
# Compile with VCS
# ============================
compile: dpi
	cd $(buildpath) && g++ -w -fPIC -I $(VCS_HOME)/include -I $(UVM_HOME)/src -DVCS \
		-c $(UVM_HOME)/src/dpi/uvm_dpi.cc -o uvm_dpi.o

	@echo "=== Compiling with VCS ==="
	sed -i -e 's/-svinputport=compat//g' -e '/tb_fifo.sv/d' $(buildpath)/compile.tcl

	cd $(buildpath) && source $(buildpath)/compile.tcl \
		2>&1 | tee $(VCS_COMPILE_LOG)

	cd $(buildpath) && $(VCS) $(VCS_SV_FLAGS) -o ./simv \
		2>&1 | tee $(VCS_ELAB_LOG)

	@echo "=== VCS Compilation & Elaboration complete ==="

# ============================
# Run simulation
# ============================
run:
	@echo "=== Running with VCS ==="
	cd $(buildpath) && ./simv +fsdbfile+sim.fsdb +UVM_TESTNAME=ita_simple_test | tee run.log

# Wave with GUI
wave:
	@echo "=== Running VCS with waves ==="
	cd $(buildpath) && ./simv +fsdbfile+sim.fsdb | tee run.log

# Clean
clean:
	rm -rf $(buildpath)/simv*
	rm -rf $(buildpath)/AN.DB
	rm -rf $(buildpath)/csrc
	rm -rf $(buildpath)/*.log
	rm -rf $(DPI_DIR)/ita_dpi.so     # ← also clean DPI lib
	rm -rf $(buildpath)/vc_hdrs.h
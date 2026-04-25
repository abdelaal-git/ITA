# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

SHELL = /usr/bin/env bash
ROOT_DIR := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

INSTALL_PREFIX        ?= install
INSTALL_DIR           = ${ROOT_DIR}/${INSTALL_PREFIX}
BENDER_INSTALL_DIR    = ${INSTALL_DIR}/bender

VENV_BIN=venv/bin/

BENDER_VERSION = 0.28.1
SIM_PATH   ?= vcs/build
SYNTH_PATH  = synopsys

# Default simulator: vcs
SIM_TOOL   ?= vcs

BENDER_TARGETS = -t rtl -t test

target ?= run

# VCS Settings
VCS_HOME       := /package/eda2/synopsys/vcs/X-2025.06-SP2-2
VERDI_HOME     := /package/eda2/synopsys/verdi/X-2025.06-SP2-2
VCS_INC_DIR    ?= +incdir+src/tb+src
VCS_DEFINES    ?= $(vlog_defs)
VCS_SV_FLAGS   ?= -sverilog -timescale=1ns/1ps -vpi -full64
VCS_COMPILE_LOG ?= vcs_compile.log

no_stalls ?= 0
single_attention ?= 0
s ?= 64
e ?= 128
p ?= 192
f ?= 64
bias ?= 0
activation ?= identity
ifeq ($(activation), gelu)
	activation_int = 1
else ifeq ($(activation), relu)
	activation_int = 2
else
	activation_int = 0
endif
vlog_defs += -DNO_STALLS=$(no_stalls) -DSINGLE_ATTENTION=$(single_attention) -DSEQ_LENGTH=$(s) -DEMBED_SIZE=$(e) -DPROJ_SPACE=$(p) -DFF_SIZE=$(f) -DBIAS=$(bias) -DACTIVATION=$(activation_int)

ifeq ($(target), sim_ita_hwpe_tb)
	BENDER_TARGETS += -t ita_hwpe -t ita_hwpe_test
	vlog_defs += -DHCI_ASSERT_DELAY=\#41ps
endif

VLOG_FLAGS += -override_timescale=1ns/1ps

# Environment variables for UVM
export UVM_HOME ?= /path/to/uvm

.PHONY: clean-sim compile run synopsys-script
all: testvector compile run

clean-sim:
	rm -rf $(SIM_PATH)/work
	rm -rf $(SIM_PATH)/compile.tcl
	rm -rf $(SIM_PATH)/wlft*
	rm -rf $(SIM_PATH)/transcript
	rm -rf $(SIM_PATH)/modelsim.ini
	rm -rf $(SIM_PATH)/vsim.wlf
	rm -rf $(SIM_PATH)/simv*
	rm -rf $(SIM_PATH)/AN.DB
	rm -rf $(SIM_PATH)/csrc
	rm -rf $(SIM_PATH)/*.log
	rm -rf $(SIM_PATH)/inter.vpd
	rm -rf $(SIM_PATH)/vc_hdrs.h
	rm -rf $(SIM_PATH)/.vcs*

compile: clean-sim
	mkdir -p $(SIM_PATH)
	$(BENDER_INSTALL_DIR)/bender script $(SIM_TOOL) $(BENDER_TARGETS) $(vlog_defs) --vlog-arg="$(VLOG_FLAGS)" >>  $(SIM_PATH)/compile.tcl
	cd $(SIM_TOOL) && \
	$(MAKE) compile buildpath=$(ROOT_DIR)/$(SIM_PATH)
run: 
	cd $(SIM_TOOL) && \
	$(MAKE) $(target) buildpath=$(ROOT_DIR)/$(SIM_PATH)

synopsys-script:
	rm ../ita-gf22/$(SYNTH_PATH)/scripts/analyze.tcl
	$(BENDER_INSTALL_DIR)/bender script synopsys -t rtl $(vlog_defs) >> ../ita-gf22/$(SYNTH_PATH)/scripts/analyze.tcl

testvector:
	@if [ ! -d "${ROOT_DIR}/${VENV_BIN}" ]; then \
		echo "Please create a virtual environment and install the required packages"; \
		echo "Run the following commands:"; \
		echo '  $$> python3 -m venv venv'; \
		echo '  $$> source venv/bin/activate'; \
		echo '  $$> pip install -r requirements.txt'; \
		exit 1; \
	fi
	@echo "Generating test vector"
	@if [ $(bias) -eq 0 ]; then \
		source ${ROOT_DIR}/${VENV_BIN}/activate; \
		${VENV_BIN}/python testGenerator.py -S $(s) -P $(p) -E $(e) -B 1 -H 1 --no-bias; \
	else \
		source ${ROOT_DIR}/${VENV_BIN}/activate; \
		${VENV_BIN}/python testGenerator.py -S $(s) -P $(p) -E $(e) -B 1 -H 1; \
	fi

# Bender
bender: check-bender
	$(BENDER_INSTALL_DIR)/bender update
	$(BENDER_INSTALL_DIR)/bender vendor init

check-bender:
	@if [ -x $(BENDER_INSTALL_DIR)/bender ]; then \
		req="bender $(BENDER_VERSION)"; \
		current="$$($(BENDER_INSTALL_DIR)/bender --version)"; \
		if [ "$$(printf '%s\n' "$${req}" "$${current}" | sort -V | head -n1)" != "$${req}" ]; then \
			rm -rf $(BENDER_INSTALL_DIR); \
		fi \
	fi
	@$(MAKE) -C $(ROOT_DIR) $(BENDER_INSTALL_DIR)/bender

$(BENDER_INSTALL_DIR)/bender:
	mkdir -p $(BENDER_INSTALL_DIR) && cd $(BENDER_INSTALL_DIR) && \
	curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh -s -- $(BENDER_VERSION)

# ============================================================
# Verilator Simulation (WSL1 / Linux)
# ============================================================

VERILATOR_BUILD = verilator_build
VERILATOR_TOP   = $(target)

verilate: clean-verilator
	mkdir -p $(VERILATOR_BUILD)
	# Generate Verilator filelist using Bender
	$(BENDER_INSTALL_DIR)/bender script verilator $(BENDER_TARGETS) $(vlog_defs) > $(VERILATOR_BUILD)/files.f

	# Build Verilator simulation
	verilator -Wall -sv --cc --exe --build \
		--top-module $(VERILATOR_TOP) \
		-f $(VERILATOR_BUILD)/files.f \
		$(VERILATOR_BUILD)/sim_main.cpp

run-verilator:
	./$(VERILATOR_BUILD)/obj_dir/V$(VERILATOR_TOP)

clean-verilator:
	rm -rf $(VERILATOR_BUILD)

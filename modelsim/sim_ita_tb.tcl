# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
if {![info exists DEBUG]} {
    set DEBUG OFF
}

# Set working library.
set LIB work

if {$DEBUG == "ON"} {
    set VOPT_ARG "-voptargs=+acc"
    echo $VOPT_ARG
    set DB_SW "-debugdb"
} else {
    set VOPT_ARG ""
    set DB_SW ""
}

quit -sim

vsim $VOPT_ARG $DB_SW -pedanticerrors -lib $LIB ita_tb

# Fix WSL absolute path issue (must be AFTER vsim)
set PrefSourcePathMap {"///home" "/home"}

if {$DEBUG == "ON"} {
    add log -r /*
    source ../sim_ita_tb_wave.tcl
}

run -a

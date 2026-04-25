# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

if {![info exists DEBUG]} {
    set DEBUG OFF
}

quit -sim

# Run VCS simulation
./simv -ucli -do "run -all; quit"

# Exit with status
exit [expr {$?}]
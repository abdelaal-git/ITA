// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_PKG_SV
`define ITA_UVM_PKG_SV

package ita_uvm_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import ita_package::*;

  // Include UVM files
  `include "ita_uvm_types.sv"
  `include "ita_uvm_config.sv"
  `include "ita_uvm_sequences.sv"
  `include "ita_uvm_agents.sv"
  `include "ita_uvm_env.sv"
  `include "ita_uvm_test.sv"

endpackage : ita_uvm_pkg

`endif</content>
<parameter name="filePath">d:\MSc\Purdue\69500\Project\ITA\src\tb\ita_uvm_pkg.sv
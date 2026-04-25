// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_ENV_SV
`define ITA_UVM_ENV_SV

class ita_env extends uvm_env;
  `uvm_component_utils(ita_env)

  // Agents
  axi_lite_agent axi_lite_master;
  axi4_agent     axi4_master;

  // Configuration
  ita_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get configuration
    if (!uvm_config_db#(ita_config)::get(this, "", "cfg", cfg))
      `uvm_error("ENV", "Configuration not found")

    // Create agents
    axi_lite_master = axi_lite_agent::type_id::create("axi_lite_master", this);
    axi_lite_master.is_active = UVM_ACTIVE;

    axi4_master = axi4_agent::type_id::create("axi4_master", this);
    axi4_master.is_active = UVM_PASSIVE;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect analysis ports if needed for scoreboard
  endfunction

endclass : ita_env

`endif

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
    axi4_master.is_active = UVM_ACTIVE;

    // Set virtual interfaces
    uvm_config_db#(virtual axi_lite_if)::set(this, "axi_lite_master.*", "axi_lite_vif", cfg.axi_lite_vif);
    uvm_config_db#(virtual axi4_if)::set(this, "axi4_master.*", "axi4_vif", cfg.axi4_vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect analysis ports if needed for scoreboard
  endfunction

endclass : ita_env

`endif</content>
<parameter name="filePath">d:\MSc\Purdue\69500\Project\ITA\src\tb\ita_uvm_env.sv
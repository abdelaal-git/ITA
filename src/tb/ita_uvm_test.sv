// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_TEST_SV
`define ITA_UVM_TEST_SV

class ita_base_test extends uvm_test;
  `uvm_component_utils(ita_base_test)

  ita_env env;
  ita_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create configuration
    cfg = ita_config::type_id::create("cfg");

    // Set configuration in database
    uvm_config_db#(ita_config)::set(this, "*", "cfg", cfg);

    // Create environment
    env = ita_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "Starting ITA UVM test", UVM_MEDIUM)

    // Wait for reset
    #100ns;

    // Run test sequence
    run_test_sequence();

    phase.drop_objection(this);
  endtask

  virtual task run_test_sequence();
    // Base implementation - override in derived tests
    `uvm_info("TEST", "Running base test sequence", UVM_MEDIUM)
  endtask

endclass : ita_base_test

class ita_simple_test extends ita_base_test;
  `uvm_component_utils(ita_simple_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_test_sequence();
    ita_test_seq seq;

    seq = ita_test_seq::type_id::create("seq");
    seq.cfg = cfg;

    seq.start(env.axi_lite_master.sequencer);
  endtask

endclass : ita_simple_test

`endif</content>
<parameter name="filePath">d:\MSc\Purdue\69500\Project\ITA\src\tb\ita_uvm_env.sv
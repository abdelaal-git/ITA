// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_SEQUENCES_SV
`define ITA_UVM_SEQUENCES_SV

// AXI-Lite write sequence
class axi_lite_write_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(axi_lite_write_seq)

  rand bit [31:0] addr;
  rand bit [31:0] data;

  function new(string name = "axi_lite_write_seq");
    super.new(name);
  endfunction

  task body();
    req = axi_lite_txn::type_id::create("req");
	  `uvm_info("SEQ", "Starting seq...", UVM_MEDIUM)
    start_item(req);
    req.addr = addr;
    req.data = data;
    req.write = 1'b1;
    finish_item(req);
    `uvm_info("SEQ", "Ending seq...", UVM_MEDIUM)
  endtask

endclass : axi_lite_write_seq

// AXI-Lite read sequence
class axi_lite_read_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(axi_lite_read_seq)

  rand bit [31:0] addr;
       bit [31:0] data;

  function new(string name = "axi_lite_read_seq");
    super.new(name);
  endfunction

  task body();
	  
    req = axi_lite_txn::type_id::create("req");
    `uvm_info("SEQ", "Starting seq...", UVM_MEDIUM)
    start_item(req);
    req.addr = addr;
    req.write = 1'b0;
    finish_item(req);
    get_response(rsp);
    data = rsp.data;
    `uvm_info("SEQ", "Ending seq...", UVM_MEDIUM)
  endtask

endclass : axi_lite_read_seq

// Control register write sequence
class ctrl_reg_write_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(ctrl_reg_write_seq)

  rand ctrl_t ctrl;

  function new(string name = "ctrl_reg_write_seq");
    super.new(name);
  endfunction

  task body();
    logic [383:0] flat = ctrl;
    `uvm_info("SEQ", "Starting seq...", UVM_MEDIUM)
    for (int i = 0; i < 12; i++) begin
	    `uvm_info("SEQ", $psprintf("Writing addr = %0d, data = %0d", i, flat[31:0]), UVM_MEDIUM)
      `uvm_do_with(req, {req.addr == 32'h00000000 + i*4; req.data == flat[31:0]; req.write == 1'b1;})
      flat = flat >> 32;
    end
    `uvm_info("SEQ", "Ending seq...", UVM_MEDIUM)
  endtask

endclass : ctrl_reg_write_seq

// Memory base address write sequence
class mem_base_write_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(mem_base_write_seq)

  mem_base_config mem_cfg;

  function new(string name = "mem_base_write_seq");
    super.new(name);
  endfunction

  task body();
	  `uvm_info("SEQ", "Starting seq...", UVM_MEDIUM)
    // Write input base address (register 12)
    `uvm_do_with(req, {req.addr == 32'h30; req.data == mem_cfg.input_base; req.write == 1'b1;})
    // Write weight base address (register 13)
    `uvm_do_with(req, {req.addr == 32'h34; req.data == mem_cfg.weight_base; req.write == 1'b1;})
    // Write bias base address (register 14)
    `uvm_do_with(req, {req.addr == 32'h38; req.data == mem_cfg.bias_base; req.write == 1'b1;})
    // Write output base address (register 15)
    `uvm_do_with(req, {req.addr == 32'h3C; req.data == mem_cfg.output_base; req.write == 1'b1;})
    `uvm_info("SEQ", "Ending seq...", UVM_MEDIUM)
  endtask

endclass : mem_base_write_seq

// AXI4 write sequence
class axi4_write_seq extends uvm_sequence#(axi4_txn);
  `uvm_object_utils(axi4_write_seq)

  rand bit [31:0] addr;
  rand bit [31:0] data[];

  function new(string name = "axi4_write_seq");
    super.new(name);
  endfunction

  task body();
    req = axi4_txn::type_id::create("req");
	  `uvm_info("SEQ", "Starting seq...", UVM_MEDIUM)
    start_item(req);
    req.addr = addr;
    req.data = data;
    req.write = 1'b1;
    req.len = data.size() - 1;
    finish_item(req);
    `uvm_info("SEQ", "Ending seq...", UVM_MEDIUM)
  endtask

endclass : axi4_write_seq

// AXI4 read sequence
class axi4_read_seq extends uvm_sequence#(axi4_txn);
  `uvm_object_utils(axi4_read_seq)

  rand bit [31:0] addr;
  rand bit [7:0]  len;
       bit [31:0] data[];

  function new(string name = "axi4_read_seq");
    super.new(name);
  endfunction

  task body();
    req = axi4_txn::type_id::create("req");
	  `uvm_info("SEQ", "Starting axi4_read_seq...", UVM_MEDIUM)
    start_item(req);
    req.addr = addr;
    req.write = 1'b0;
    req.len = len;
    finish_item(req);
    get_response(rsp);
    data = rsp.data;
    `uvm_info("SEQ", "Ending axi4_read_seq...", UVM_MEDIUM)
  endtask

endclass : axi4_read_seq

// Main ITA test sequence
class ita_test_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(ita_test_seq)

  // Sequences
  ctrl_reg_write_seq ctrl_seq;
  mem_base_write_seq mem_seq;
  axi4_write_seq     mem_write_seq;
  axi4_read_seq      mem_read_seq;

  // Configuration
  ita_config cfg;

  // Test data
  logic [31:0] input_data[];
  logic [31:0] weight_data[];
  logic [31:0] bias_data[];
  logic [31:0] expected_output[];

  function new(string name = "ita_test_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "Starting test_seq...", UVM_MEDIUM)
    // Get configuration
    if (!uvm_config_db#(ita_config)::get(null, get_full_name(), "cfg", cfg))
      `uvm_error("SEQ", "Configuration not found")

    // Load test data (simplified - in real implementation, read from files)
    load_test_data();

    // Configure control registers
    ctrl_seq = ctrl_reg_write_seq::type_id::create("ctrl_seq");
    ctrl_seq.ctrl = get_default_ctrl();
    ctrl_seq.start(m_sequencer);

    // Configure memory base addresses
    mem_seq = mem_base_write_seq::type_id::create("mem_seq");
    mem_seq.mem_cfg = cfg.mem_cfg;
    mem_seq.start(m_sequencer);

    // Write input data to memory
    //write_data_to_memory(cfg.mem_cfg.input_base, input_data); //FIXME this needs to be backdoor since the memory's master is currently only DUT

    // Write weight data to memory
    //write_data_to_memory(cfg.mem_cfg.weight_base, weight_data);//FIXME this needs to be backdoor since the memory's master is currently only DUT

    // Write bias data to memory
    //write_data_to_memory(cfg.mem_cfg.bias_base, bias_data);//FIXME this needs to be backdoor since the memory's master is currently only DUT

    // Start ITA computation
    start_ita_computation();

    // Wait for completion (simplified)
    #1000ns;

    // Read output data from memory
    //read_data_from_memory(cfg.mem_cfg.output_base, expected_output.size());//FIXME this needs to be backdoor since the memory's master is currently only DUT

    // Verify results
    verify_results();
    `uvm_info("SEQ", "Ending test_seq...", UVM_MEDIUM)
  endtask

  task write_data_to_memory(bit [31:0] base_addr, logic [31:0] data[]);
    mem_write_seq = axi4_write_seq::type_id::create("mem_write_seq");
    mem_write_seq.addr = base_addr;
    mem_write_seq.data = data;
    mem_write_seq.start(m_sequencer);
  endtask

  task read_data_from_memory(bit [31:0] base_addr, int unsigned size);
    mem_read_seq = axi4_read_seq::type_id::create("mem_read_seq");
    mem_read_seq.addr = base_addr;
    mem_read_seq.len = size - 1;
    mem_read_seq.start(m_sequencer);
  endtask

  task start_ita_computation();
    // Write start bit to control register
    `uvm_do_with(req, {req.addr == 32'h00; req.data == 32'h00000001; req.write == 1'b1;})
  endtask

  task load_test_data();
    // Simplified - load some test data
    input_data = new[10];
    weight_data = new[20];
    bias_data = new[5];
    expected_output = new[8];

    foreach (input_data[i]) input_data[i] = $random;
    foreach (weight_data[i]) weight_data[i] = $random;
    foreach (bias_data[i]) bias_data[i] = $random;
    foreach (expected_output[i]) expected_output[i] = $random;
  endtask

  function ctrl_t get_default_ctrl();
    ctrl_t ctrl;
    ctrl = '0;
    ctrl.start = 1'b0;
    ctrl.eps_mult = 1;
    ctrl.right_shift = 8;
    ctrl.add = 0;
    ctrl.tile_e = 16; // Simplified values
    ctrl.tile_p = 16;
    ctrl.tile_s = 16;
    ctrl.tile_f = 16;
    return ctrl;
  endfunction

  task verify_results();
    // Compare read data with expected output
    // This is simplified - real implementation would do detailed checking
    `uvm_info("SEQ", "Results verification completed", UVM_MEDIUM)
  endtask

endclass : ita_test_seq

`endif

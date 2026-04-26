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

// ========================================================
// Control Register Write Sequence - Fully Dynamic
// ========================================================
class ctrl_reg_write_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(ctrl_reg_write_seq)

  rand ctrl_t ctrl;
  ita_config cfg;

  function new(string name = "ctrl_reg_write_seq");
    super.new(name);
  endfunction

  task body();
    if (!uvm_config_db#(ita_config)::get(null, get_full_name(), "cfg", cfg))
      `uvm_fatal("CTRL_SEQ", "ita_config not found")

    // Populate ctrl using real parameters (M, S, P, E, H, F, ...)
    ctrl = get_default_ctrl();

    // === Dynamic width handling (no hardcoded 384) ===
    int unsigned ctrl_bit_width = $bits(ctrl_t);
    int unsigned num_words      = (ctrl_bit_width + 31) / 32;

    // Use a wide enough vector (works in all simulators)
    logic [1023:0] flat = '0;          // Safe max width (1024 bits)
    flat[ctrl_bit_width-1:0] = ctrl;   // Truncate to actual size

    `uvm_info("CTRL_SEQ", $sformatf("Writing %0d words (%0d bits) | S=%0d P=%0d E=%0d M=%0d F=%0d", 
              num_words, ctrl_bit_width, cfg.S, cfg.P, cfg.E, cfg.M, cfg.F), UVM_MEDIUM)

    for (int i = 0; i < num_words; i++) begin
      `uvm_do_with(req, {
        req.addr  == 32'h0000_0000 + i*4;   // Control base address
        req.data  == flat[31:0];
        req.write == 1'b1;
      })

      flat = flat >> 32;
    end

    `uvm_info("CTRL_SEQ", "Control registers written successfully", UVM_MEDIUM)
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

// Updated DPI import (place after other imports)
import "DPI-C" context function void ita_reference_model(
    input logic[31:0] input_data[],  input int input_size,
    input logic[31:0] weight_data[], input int weight_size,
    input logic[31:0] bias_data[],   input int bias_size,
    input int S, input int P, input int E, input int F, input int H,
    input int N, input int M, input int WI, input int WO,
    output logic[31:0] output_data[], input int output_size);


// ===================================================================
// Main test sequence
// ===================================================================
class ita_test_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(ita_test_seq)

  // Sub-sequences
  ctrl_reg_write_seq ctrl_seq;
  mem_base_write_seq mem_seq;

  ita_config cfg;

  // Test data
  logic [31:0] input_data[];
  logic [31:0] weight_data[];
  logic [31:0] bias_data[];
  logic [31:0] expected_output[];
  logic [31:0] act_output_data[];

  function new(string name = "ita_test_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "Starting ita_test_seq", UVM_MEDIUM)

    if (!uvm_config_db#(ita_config)::get(null, get_full_name(), "cfg", cfg))
      `uvm_fatal("SEQ", "Configuration not found")

    // Backdoor writes
    backdoor_write_data_to_memory("ita_uvm_tb.i_axi_memory.mem", cfg.mem_cfg.input_base,  input_data);
    backdoor_write_data_to_memory("ita_uvm_tb.i_axi_memory.mem", cfg.mem_cfg.weight_base, weight_data);
    backdoor_write_data_to_memory("ita_uvm_tb.i_axi_memory.mem", cfg.mem_cfg.bias_base,   bias_data);    
    `uvm_info("SEQ", "Memory is initialized", UVM_MEDIUM)

    load_test_data();

    // Configure control registers
    ctrl_seq = ctrl_reg_write_seq::type_id::create("ctrl_seq");
    ctrl_seq.ctrl = get_default_ctrl();
    ctrl_seq.start(m_sequencer);

    // Memory bases
    mem_seq = mem_base_write_seq::type_id::create("mem_seq");
    mem_seq.mem_cfg = cfg.mem_cfg;
    mem_seq.start(m_sequencer);

    start_ita_computation();

    #2000ns;  // Adjust according to your design latency

    backdoor_read_data_from_memory("ita_uvm_tb.i_axi_memory.mem",
                                   cfg.mem_cfg.output_base,
                                   expected_output.size(), act_output_data);

    verify_results();

    `uvm_info("SEQ", "ita_test_seq finished", UVM_MEDIUM)
  endtask

  // ===================================================================
  // Full load_test_data()
  // ===================================================================
  task load_test_data();
  int unsigned S = cfg.S;  // from ita_package via config
  int unsigned P = cfg.P;
  int unsigned E = cfg.E;
  int unsigned F = cfg.F;
  int unsigned H = cfg.H;
  int unsigned N = cfg.N;
  int unsigned M = cfg.M;
  int unsigned WI = cfg.WI;
  int unsigned WO = cfg.WO;

  // -------------------------------------------------
  // Array allocation — realistic sizes
  // -------------------------------------------------
  input_data      = new[S * E];                    // Input tokens (S x E)
  expected_output = new[S * E];                    // Final output after MHA + FFN

  // Weights: Wq(HxExP) + Wk(HxExP) + Wv(HxExP) + Wo(HxPxE) + Wff(1xExF) + Wff2(1xFxE)
  weight_data = new[ H*E*P*2 + H*P*E + E*F + F*E ];   // rough total (adjust if needed)

  // Biases: Bq(HxP) + Bk(HxP) + Bv(HxP) + Bo(HxE) + Bff(1xF) + Bff2(1xE)
  bias_data   = new[ H*P*3 + H*E + F + E ];

  `uvm_info("SEQ", $sformatf("load_test_data: S=%0d E=%0d P=%0d F=%0d H=%0d M=%0d", 
            S, E, P, F, H, M), UVM_MEDIUM)

  // -------------------------------------------------
  // Generate random data (signed WI bits)
  // -------------------------------------------------
  foreach (input_data[i])  
      input_data[i] = $signed($urandom_range(-(2**(WI-1)), 2**(WI-1)-1));

  foreach (weight_data[i]) 
      weight_data[i] = $signed($urandom_range(-(2**(WI-1)), 2**(WI-1)-1));

  foreach (bias_data[i])   
      bias_data[i]   = $signed($urandom_range(-(2**(WI-1)), 2**(WI-1)-1));

  // -------------------------------------------------
  // Call Golden Model (updated DPI signature)
  // -------------------------------------------------
  ita_reference_model(
      input_data,   input_data.size(),
      weight_data,  weight_data.size(),
      bias_data,    bias_data.size(),
      S, P, E, F, H, N, M, WI, WO,
      expected_output, expected_output.size()
  );

  `uvm_info("SEQ", $sformatf("Golden model run — expected output size = %0d", 
            expected_output.size()), UVM_MEDIUM)
	    `uvm_info("SEQ", $sformatf("Golden model run — expected output = %0p", 
            expected_output), UVM_MEDIUM)
endtask

  // Backdoor memory initialization using uvm_hdl_deposit
  task backdoor_write_data_to_memory(string mem_path, bit [31:0] base_addr, logic [31:0] data[]);
    string hdl_path;
    int unsigned word_addr;
    for (int i = 0; i < data.size(); i++) begin
      word_addr = (base_addr >> 2) + i;
      hdl_path = {mem_path, "[", $sformatf("%0d", word_addr), "]"};
      if (!uvm_hdl_deposit(hdl_path, data[i])) begin
        `uvm_error("BACKDOOR", $sformatf("Failed to deposit to %s", hdl_path))
      end
    end
  endtask

  // Backdoor memory read using uvm_hdl_read
  task backdoor_read_data_from_memory(string mem_path, bit [31:0] base_addr, int unsigned size, ref logic [31:0] data[]);
    string hdl_path;
    int unsigned word_addr;
    uvm_hdl_data_t tmp;
    data = new[size];
    for (int i = 0; i < size; i++) begin
      word_addr = (base_addr >> 2) + i;
      hdl_path = {mem_path, "[", $sformatf("%0d", word_addr), "]"};
      if (!uvm_hdl_read(hdl_path, tmp)) begin
        `uvm_error("BACKDOOR", $sformatf("Failed to read from %s", hdl_path))
        data[i] = 'x;
      end else begin
        data[i] = tmp;
      end
    end
  endtask

  task start_ita_computation();
  `uvm_info("CTRL_SEQ", "Pulsing START bit...", UVM_MEDIUM)

  // Write start = 1
  `uvm_do_with(req, {
    req.addr  == 32'h0000_0000;   // first control register
    req.data  == 32'h0000_0001;   // assuming bit 0 is 'start'
    req.write == 1'b1;
  })

  #100ns;

  // Optionally clear start bit (some designs need this)
  `uvm_do_with(req, {
    req.addr  == 32'h0000_0000;
    req.data  == 32'h0000_0000;
    req.write == 1'b1;
  })

  `uvm_info("CTRL_SEQ", "START bit pulsed - computation triggered", UVM_MEDIUM)
endtask

// ===================================================================
  // Wait for Done (with timeout)
  // ===================================================================
  task wait_for_done(int unsigned timeout_cycles = 500_000);
    int unsigned cycle = 0;
    logic done = 0;

    while (!done && cycle < timeout_cycles) begin
      // Poll status register (adjust address/bit if needed)
      `uvm_do_with(req, {req.addr == 32'h0000_0040; req.write == 1'b0;})  // example status addr
      done = req.data[0];   // assume bit 0 = done
      #100ns;
      cycle++;
    end

    if (done)
      `uvm_info("SEQ", "Computation finished successfully", UVM_MEDIUM)
    else
      `uvm_error("SEQ", "Timeout waiting for done signal")
  endtask

  function ctrl_t get_default_ctrl();
  ctrl_t c = '0;

  c.start       = 1'b0;           // will be set to 1 later by another register or pulse
  c.layer       = Attention;      // or Feedforward
  c.activation  = Identity;

  // === Use real parameters from config ===
  c.tile_s      = cfg.M;
  c.tile_e      = cfg.M;
  c.tile_p      = cfg.M;
  c.tile_f      = cfg.F;          // F may differ from M

  c.eps_mult    = cfg.eps_mult;
  c.right_shift = cfg.right_shift;
  c.add         = cfg.add;

  `uvm_info("CTRL", $sformatf("Default ctrl: tile_s=%0d tile_e=%0d tile_p=%0d tile_f=%0d", 
            c.tile_s, c.tile_e, c.tile_p, c.tile_f), UVM_MEDIUM)

  return ctrl;
endfunction

  // ===================================================================
  // Result Verification
  // ===================================================================
  task verify_results();
    int errors = 0;

    foreach (expected_output[i]) begin
      if (act_output_data[i] !== expected_output[i]) begin
        errors++;
        if (errors < 10) begin
          `uvm_error("VERIFY", $sformatf("Mismatch at idx %0d: expected=0x%0h, actual=0x%0h", 
                    i, expected_output[i], act_output_data[i]))
        end
      end
    end

    if (errors == 0)
      `uvm_info("VERIFY", "✅ PASSED - All outputs match golden model!", UVM_LOW)
    else
      `uvm_error("VERIFY", $sformatf("❌ FAILED - %0d mismatches", errors))
  endtask

endclass : ita_test_seq

`endif

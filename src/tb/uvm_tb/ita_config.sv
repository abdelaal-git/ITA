// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_CONFIG_SV
`define ITA_CONFIG_SV

class ita_config extends uvm_object;
  `uvm_object_utils(ita_config)

  // -------------------------------------------------------------------------
  // Virtual interface handle
  // Passed from the top-level testbench to the agent's driver and monitor
  // via uvm_config_db.
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // Agent activity mode
  // UVM_ACTIVE  – agent drives the DUT (driver + sequencer + monitor)
  // UVM_PASSIVE – agent only observes (monitor only)
  // -------------------------------------------------------------------------
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // -------------------------------------------------------------------------
  // Memory base address configuration
  // Used by ita_test_seq to program the DUT's memory-pointer registers and
  // by mem_base_write_seq to issue the corresponding AXI-Lite writes.
  // -------------------------------------------------------------------------
   rand mem_base_config mem_cfg;

  // -------------------------------------------------------------------------
  // ITA tile / shape parameters
  // Match the defaults used in ita_test_seq::get_default_ctrl().
  // Tests can override these before calling uvm_config_db::set().
  // -------------------------------------------------------------------------
  int unsigned tile_e = 16;   // embedding dimension tile
  int unsigned tile_p = 16;   // projection dimension tile
  int unsigned tile_s = 16;   // sequence-length tile
  int unsigned tile_f = 16;   // feed-forward dimension tile

  // -------------------------------------------------------------------------
  // Quantisation / arithmetic parameters
  // -------------------------------------------------------------------------
  int unsigned eps_mult    = 1;  // epsilon multiplier
  int unsigned right_shift = 8;  // post-accumulation right shift
  int          add         = 0;  // additive bias term

  // -------------------------------------------------------------------------
  // Simulation knobs
  // -------------------------------------------------------------------------
  // Maximum number of clock cycles to wait for the ITA done interrupt / status
  // bit before the scoreboard/test raises a timeout error.
  int unsigned timeout_cycles = 100_000;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ita_config");
    super.new(name);
    // Allocate the memory-config sub-object with its default base addresses.
    mem_cfg = mem_base_config::type_id::create("mem_cfg");
  endfunction

  // -------------------------------------------------------------------------
  // do_copy
  // -------------------------------------------------------------------------
  virtual function void do_copy(uvm_object rhs);
    ita_config rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs))
      `uvm_fatal("CONFIG", "do_copy: type mismatch")
    is_active    = rhs_.is_active;
    tile_e       = rhs_.tile_e;
    tile_p       = rhs_.tile_p;
    tile_s       = rhs_.tile_s;
    tile_f       = rhs_.tile_f;
    eps_mult     = rhs_.eps_mult;
    right_shift  = rhs_.right_shift;
    add          = rhs_.add;
    timeout_cycles = rhs_.timeout_cycles;
    mem_cfg.copy(rhs_.mem_cfg);
  endfunction

endclass : ita_config

`endif // ITA_CONFIG_SV

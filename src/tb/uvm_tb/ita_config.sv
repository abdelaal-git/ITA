// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_CONFIG_SV
`define ITA_CONFIG_SV

class ita_config extends uvm_object;
  `uvm_object_utils(ita_config)

  rand mem_base_config mem_cfg;

  // -------------------------------------------------------------------------
  // Parameters synced from ita_package / DUT
  // -------------------------------------------------------------------------
  int unsigned N;   // parallelism
  int unsigned M;   // tile size
  int unsigned S;   // sequence length
  int unsigned P;   // projection dim
  int unsigned E;   // embedding dim
  int unsigned H;   // heads

  int unsigned F = 64;   // Feed-forward (not in package) → override with +F=xx

  int unsigned WI = 8;   // weight/input bitwidth
  int unsigned WO = 26;  // output/accumulator bitwidth

  int unsigned eps_mult    = 1;
  int unsigned right_shift = 8;
  int          add         = 0;

  int unsigned timeout_cycles = 1_000_000;

  // Timing parameters (synced from ita_tb.sv)
  int unsigned CLK_PERIOD = 2000;  // ps
  int unsigned APPL_DELAY  = 400;  // ps

  // Test mode control
  int unsigned SINGLE_ATTENTION = 0;  // 0=normal attention, 1=single attention mode
  int unsigned ITERS             = 1;  // number of iterations

  // -------------------------------------------------------------------------
  function new(string name = "ita_config");
    string s;
    super.new(name);
    mem_cfg = mem_base_config::type_id::create("mem_cfg");

    // Pull from ita_package (adjust names if your package uses different ones)
    N = ita_package::N;
    M = ita_package::M;
    S = ita_package::S;
    P = ita_package::P;
    E = ita_package::E;
    H = ita_package::H;

    // F via plusarg
    if ($value$plusargs("F=%d", s)) F = s.atoi();
    else F = 64;

    // SINGLE_ATTENTION via plusarg
    if ($value$plusargs("SINGLE_ATTENTION=%d", s)) SINGLE_ATTENTION = s.atoi();

    // ITERS via plusarg
    if ($value$plusargs("ITERS=%d", s)) ITERS = s.atoi();

    mem_cfg.calculate_addresses(S, E, P, H, F);

    `uvm_info("CONFIG", $sformatf("DUT params → N=%0d M=%0d S=%0d P=%0d E=%0d H=%0d F=%0d WI=%0d WO=%0d",
              N,M,S,P,E,H,F,WI,WO), UVM_LOW)
  endfunction

endclass : ita_config

`endif

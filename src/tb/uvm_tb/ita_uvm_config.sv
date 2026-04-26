// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_TYPES_SV
`define ITA_UVM_TYPES_SV

// AXI-Lite transaction for control registers
class axi_lite_txn extends uvm_sequence_item;
  `uvm_object_utils(axi_lite_txn)

  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        write;  // 1=write, 0=read

  function new(string name = "axi_lite_txn");
    super.new(name);
  endfunction

endclass : axi_lite_txn

// AXI4 transaction for memory access
class axi4_txn extends uvm_sequence_item;
  `uvm_object_utils(axi4_txn)

  rand bit [31:0] addr;
  rand bit [31:0] data[];
  rand bit        write;  // 1=write, 0=read
  rand bit [7:0]  len;    // burst length
  rand bit [2:0]  size;   // burst size
  rand bit [1:0]  burst;  // burst type

  constraint burst_c {
    burst == 2'b01; // INCR burst
    size == 3'b010; // 4 bytes
  }

  function new(string name = "axi4_txn");
    super.new(name);
    data = new[1];
  endfunction

endclass : axi4_txn

// ITA control transaction
class ita_ctrl_txn extends uvm_sequence_item;
  `uvm_object_utils(ita_ctrl_txn)

  rand ctrl_t ctrl;

  function new(string name = "ita_ctrl_txn");
    super.new(name);
  endfunction

endclass : ita_ctrl_txn

// Memory base address configuration - Dynamic & Safe
class mem_base_config extends uvm_object;
  `uvm_object_utils(mem_base_config)

  bit [31:0] input_base;
  bit [31:0] weight_base;
  bit [31:0] bias_base;
  bit [31:0] output_base;

  function new(string name = "mem_base_config");
    super.new(name);
  endfunction

  // Calculate safe, non-overlapping addresses based on parameters
  function void calculate_addresses(
    int unsigned S,
    int unsigned E,
    int unsigned P,
    int unsigned H,
    int unsigned F
  );
    // Start from 0
    input_base = 32'h0000_0000;

    // Weights come after input data
    weight_base = input_base + (S * E * 4);        // 4 bytes per word

    // Bias after weights (rough but safe estimate)
    bias_base   = weight_base + (H*E*P*4 + E*F*4 + 4096);  // extra margin

    // Output after bias
    output_base = bias_base + (H*P*4 + E*4 + 4096);

    // Align all bases to 4KB boundaries (cleaner for backdoor & debugging)
    weight_base = (weight_base + 4095) & ~32'hFFF;
    bias_base   = (bias_base   + 4095) & ~32'hFFF;
    output_base = (output_base + 4095) & ~32'hFFF;

    `uvm_info("MEM_CFG", $sformatf("Calculated addresses → In:0x%0h Wt:0x%0h Bias:0x%0h Out:0x%0h",
              input_base, weight_base, bias_base, output_base), UVM_MEDIUM)
  endfunction

endclass : mem_base_config

`endif

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

// Memory base address configuration
class mem_base_config extends uvm_object;
  `uvm_object_utils(mem_base_config)

  bit [31:0] input_base  = 32'h00000000;
  bit [31:0] weight_base = 32'h00100000;
  bit [31:0] bias_base   = 32'h00200000;
  bit [31:0] output_base = 32'h00300000;

  function new(string name = "mem_base_config");
    super.new(name);
  endfunction

endclass : mem_base_config

`endif

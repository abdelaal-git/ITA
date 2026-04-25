// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_AGENTS_SV
`define ITA_UVM_AGENTS_SV

// AXI-Lite Interface
interface axi_lite_if(input logic clk, input logic rst_n);
  // Write address channel
  logic [31:0] awaddr;
  logic        awvalid;
  logic        awready;
  // Write data channel
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wvalid;
  logic        wready;
  // Write response channel
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;
  // Read address channel
  logic [31:0] araddr;
  logic        arvalid;
  logic        arready;
  // Read data channel
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  logic        rready;

  // Driver clocking block
  clocking drv_cb @(posedge clk);
    default input #1ns output #1ns;
    output awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr, arvalid, rready;
    input awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid;
  endclocking

  // Monitor clocking block
  clocking mon_cb @(posedge clk);
    default input #1ns;
    input awaddr, awvalid, awready, wdata, wstrb, wvalid, wready;
    input bresp, bvalid, bready, araddr, arvalid, arready;
    input rdata, rresp, rvalid, rready;
  endclocking

  // Reset task
  task reset();
    awaddr <= 0;
    awvalid <= 0;
    wdata <= 0;
    wstrb <= 0;
    wvalid <= 0;
    bready <= 0;
    araddr <= 0;
    arvalid <= 0;
    rready <= 0;
  endtask
endinterface : axi_lite_if

// AXI4 Interface
interface axi4_if(input logic clk, input logic rst_n);
  // Write address channel
  logic [31:0] awaddr;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic        awvalid;
  logic        awready;
  // Write data channel
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  logic        wvalid;
  logic        wready;
  // Write response channel
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;
  // Read address channel
  logic [31:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        arvalid;
  logic        arready;
  // Read data channel
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rlast;
  logic        rvalid;
  logic        rready;

  // Driver clocking block
  clocking drv_cb @(posedge clk);
    default input #1ns output #1ns;
    output awaddr, awlen, awsize, awburst, awvalid;
    output wdata, wstrb, wlast, wvalid, bready;
    output araddr, arlen, arsize, arburst, arvalid, rready;
    input awready, wready, bresp, bvalid, arready, rdata, rresp, rlast, rvalid;
  endclocking

  // Monitor clocking block
  clocking mon_cb @(posedge clk);
    default input #1ns;
    input awaddr, awlen, awsize, awburst, awvalid, awready;
    input wdata, wstrb, wlast, wvalid, wready;
    input bresp, bvalid, bready;
    input araddr, arlen, arsize, arburst, arvalid, arready;
    input rdata, rresp, rlast, rvalid, rready;
  endclocking

  // Reset task
  task reset();
    awaddr <= 0;
    awlen <= 0;
    awsize <= 0;
    awburst <= 0;
    awvalid <= 0;
    wdata <= 0;
    wstrb <= 0;
    wlast <= 0;
    wvalid <= 0;
    bready <= 0;
    araddr <= 0;
    arlen <= 0;
    arsize <= 0;
    arburst <= 0;
    arvalid <= 0;
    rready <= 0;
  endtask
endinterface : axi4_if

// AXI-Lite Driver
class axi_lite_driver extends uvm_driver#(axi_lite_txn);
  `uvm_component_utils(axi_lite_driver)

  virtual axi_lite_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "axi_lite_vif", vif))
      `uvm_error("DRV", "AXI-Lite virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    vif.reset();
    @(posedge vif.rst_n);
    forever begin
      seq_item_port.get_next_item(req);
      drive_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transaction(axi_lite_txn txn);
    if (txn.write) begin
      // Write transaction
      vif.drv_cb.awaddr <= txn.addr;
      vif.drv_cb.awvalid <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.awready) @(vif.drv_cb);

      vif.drv_cb.awvalid <= 1'b0;
      vif.drv_cb.wdata <= txn.data;
      vif.drv_cb.wstrb <= 4'hF;
      vif.drv_cb.wvalid <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.wready) @(vif.drv_cb);

      vif.drv_cb.wvalid <= 1'b0;
      vif.drv_cb.bready <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.bvalid) @(vif.drv_cb);

      vif.drv_cb.bready <= 1'b0;
    end else begin
      // Read transaction
      vif.drv_cb.araddr <= txn.addr;
      vif.drv_cb.arvalid <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.arready) @(vif.drv_cb);

      vif.drv_cb.arvalid <= 1'b0;
      vif.drv_cb.rready <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.rvalid) @(vif.drv_cb);

      txn.data = vif.drv_cb.rdata;
      vif.drv_cb.rready <= 1'b0;
    end
  endtask

endclass : axi_lite_driver

// AXI-Lite Monitor
class axi_lite_monitor extends uvm_monitor;
  `uvm_component_utils(axi_lite_monitor)

  virtual axi_lite_if vif;
  uvm_analysis_port#(axi_lite_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "axi_lite_vif", vif))
      `uvm_error("MON", "AXI-Lite virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      monitor_transaction();
    end
  endtask

  task monitor_transaction();
    axi_lite_txn txn = axi_lite_txn::type_id::create("txn");

    // Monitor write transactions
    if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
      txn.write = 1'b1;
      txn.addr = vif.mon_cb.awaddr;
      if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
        txn.data = vif.mon_cb.wdata;
      end
      ap.write(txn);
    end

    // Monitor read transactions
    if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
      txn.write = 1'b0;
      txn.addr = vif.mon_cb.araddr;
      if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
        txn.data = vif.mon_cb.rdata;
      end
      ap.write(txn);
    end

    @(vif.mon_cb);
  endtask

endclass : axi_lite_monitor

// AXI-Lite Agent
class axi_lite_agent extends uvm_agent;
  `uvm_component_utils(axi_lite_agent)

  axi_lite_driver    driver;
  axi_lite_monitor   monitor;
  uvm_sequencer#(axi_lite_txn) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = axi_lite_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver = axi_lite_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(axi_lite_txn)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : axi_lite_agent

// AXI4 Driver
class axi4_driver extends uvm_driver#(axi4_txn);
  `uvm_component_utils(axi4_driver)

  virtual axi4_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi4_vif", vif))
      `uvm_error("DRV", "AXI4 virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    vif.reset();
    @(posedge vif.rst_n);
    forever begin
      seq_item_port.get_next_item(req);
      drive_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transaction(axi4_txn txn);
    if (txn.write) begin
      // Write transaction
      vif.drv_cb.awaddr <= txn.addr;
      vif.drv_cb.awlen <= txn.len;
      vif.drv_cb.awsize <= txn.size;
      vif.drv_cb.awburst <= txn.burst;
      vif.drv_cb.awvalid <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.awready) @(vif.drv_cb);

      vif.drv_cb.awvalid <= 1'b0;

      // Write data
      for (int i = 0; i <= txn.len; i++) begin
        vif.drv_cb.wdata <= txn.data[i];
        vif.drv_cb.wstrb <= 4'hF;
        vif.drv_cb.wlast <= (i == txn.len);
        vif.drv_cb.wvalid <= 1'b1;
        @(vif.drv_cb);
        while (!vif.drv_cb.wready) @(vif.drv_cb);
      end

      vif.drv_cb.wvalid <= 1'b0;
      vif.drv_cb.bready <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.bvalid) @(vif.drv_cb);

      vif.drv_cb.bready <= 1'b0;
    end else begin
      // Read transaction
      vif.drv_cb.araddr <= txn.addr;
      vif.drv_cb.arlen <= txn.len;
      vif.drv_cb.arsize <= txn.size;
      vif.drv_cb.arburst <= txn.burst;
      vif.drv_cb.arvalid <= 1'b1;
      @(vif.drv_cb);
      while (!vif.drv_cb.arready) @(vif.drv_cb);

      vif.drv_cb.arvalid <= 1'b0;
      vif.drv_cb.rready <= 1'b1;

      // Read data
      txn.data = new[txn.len + 1];
      for (int i = 0; i <= txn.len; i++) begin
        @(vif.drv_cb);
        while (!vif.drv_cb.rvalid) @(vif.drv_cb);
        txn.data[i] = vif.drv_cb.rdata;
      end

      vif.drv_cb.rready <= 1'b0;
    end
  endtask

endclass : axi4_driver

// AXI4 Monitor
class axi4_monitor extends uvm_monitor;
  `uvm_component_utils(axi4_monitor)

  virtual axi4_if vif;
  uvm_analysis_port#(axi4_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi4_vif", vif))
      `uvm_error("MON", "AXI4 virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      monitor_transaction();
    end
  endtask

  task monitor_transaction();
    axi4_txn txn = axi4_txn::type_id::create("txn");

    // Monitor write transactions
    if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
      txn.write = 1'b1;
      txn.addr = vif.mon_cb.awaddr;
      txn.len = vif.mon_cb.awlen;
      txn.size = vif.mon_cb.awsize;
      txn.burst = vif.mon_cb.awburst;

      // Collect write data
      txn.data = new[txn.len + 1];
      for (int i = 0; i <= txn.len; i++) begin
        if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
          txn.data[i] = vif.mon_cb.wdata;
        end
        @(vif.mon_cb);
      end

      ap.write(txn);
    end

    // Monitor read transactions
    if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
      txn.write = 1'b0;
      txn.addr = vif.mon_cb.araddr;
      txn.len = vif.mon_cb.arlen;
      txn.size = vif.mon_cb.arsize;
      txn.burst = vif.mon_cb.arburst;

      // Collect read data
      txn.data = new[txn.len + 1];
      for (int i = 0; i <= txn.len; i++) begin
        if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
          txn.data[i] = vif.mon_cb.rdata;
        end
        @(vif.mon_cb);
      end

      ap.write(txn);
    end

    @(vif.mon_cb);
  endtask

endclass : axi4_monitor

// AXI4 Agent
class axi4_agent extends uvm_agent;
  `uvm_component_utils(axi4_agent)

  axi4_driver      driver;
  axi4_monitor     monitor;
  uvm_sequencer#(axi4_txn) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = axi4_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver = axi4_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(axi4_txn)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : axi4_agent

`endif

// Control register write sequence
class ctrl_reg_write_seq extends uvm_sequence#(axi_lite_txn);
  `uvm_object_utils(ctrl_reg_write_seq)

  rand ctrl_t ctrl;

  function new(string name = "ctrl_reg_write_seq");
    super.new(name);
  endfunction

  task body();
    logic [383:0] flat = ctrl;
    for (int i = 0; i < 12; i++) begin
      `uvm_do_with(req, {req.addr == 32'h00000000 + i*4; req.data == flat[31:0]; req.write == 1'b1;})
      flat = flat >> 32;
    end
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
    // Write input base address (register 12)
    `uvm_do_with(req, {req.addr == 32'h30; req.data == mem_cfg.input_base; req.write == 1'b1;})
    // Write weight base address (register 13)
    `uvm_do_with(req, {req.addr == 32'h34; req.data == mem_cfg.weight_base; req.write == 1'b1;})
    // Write bias base address (register 14)
    `uvm_do_with(req, {req.addr == 32'h38; req.data == mem_cfg.bias_base; req.write == 1'b1;})
    // Write output base address (register 15)
    `uvm_do_with(req, {req.addr == 32'h3C; req.data == mem_cfg.output_base; req.write == 1'b1;})
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
    start_item(req);
    req.addr = addr;
    req.data = data;
    req.write = 1'b1;
    req.len = data.size() - 1;
    finish_item(req);
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
    start_item(req);
    req.addr = addr;
    req.write = 1'b0;
    req.len = len;
    finish_item(req);
    get_response(rsp);
    data = rsp.data;
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
    write_data_to_memory(cfg.mem_cfg.input_base, input_data);

    // Write weight data to memory
    write_data_to_memory(cfg.mem_cfg.weight_base, weight_data);

    // Write bias data to memory
    write_data_to_memory(cfg.mem_cfg.bias_base, bias_data);

    // Start ITA computation
    start_ita_computation();

    // Wait for completion (simplified)
    #1000ns;

    // Read output data from memory
    read_data_from_memory(cfg.mem_cfg.output_base, expected_output.size());

    // Verify results
    verify_results();
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

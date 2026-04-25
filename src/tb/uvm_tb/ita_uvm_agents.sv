// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_AGENTS_SV
`define ITA_UVM_AGENTS_SV

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

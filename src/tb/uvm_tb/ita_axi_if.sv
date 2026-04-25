`ifndef ITA_AXI_IF_SV
`define ITA_AXI_IF_SV

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
`endif

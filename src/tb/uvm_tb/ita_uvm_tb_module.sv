// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

`ifndef ITA_UVM_TB_TOP_MODULE_SV
`define ITA_UVM_TB_TOP_MODULE_SV


`include "ita_coverage_assertions.sv"
`include "ita_axi_if.sv"

module ita_uvm_tb;

  import uvm_pkg::*;
  import ita_uvm_pkg::*;

  // Clock and reset
  logic clk_i;
  logic rst_ni;

  // AXI4-Lite slave interface for control registers
  logic [31:0]  s_axil_awaddr;
  logic         s_axil_awvalid;
  logic         s_axil_awready;
  logic [31:0]  s_axil_wdata;
  logic [3:0]   s_axil_wstrb;
  logic         s_axil_wvalid;
  logic         s_axil_wready;
  logic [1:0]   s_axil_bresp;
  logic         s_axil_bvalid;
  logic         s_axil_bready;
  logic [31:0]  s_axil_araddr;
  logic         s_axil_arvalid;
  logic         s_axil_arready;
  logic [31:0]  s_axil_rdata;
  logic [1:0]   s_axil_rresp;
  logic         s_axil_rvalid;
  logic         s_axil_rready;

  // AXI4 full master interface for external memory
  logic [31:0]  m_axi_awaddr;
  logic [7:0]   m_axi_awlen;
  logic [2:0]   m_axi_awsize;
  logic [1:0]   m_axi_awburst;
  logic         m_axi_awvalid;
  logic         m_axi_awready;
  logic [31:0]  m_axi_wdata;
  logic [3:0]   m_axi_wstrb;
  logic         m_axi_wlast;
  logic         m_axi_wvalid;
  logic         m_axi_wready;
  logic [1:0]   m_axi_bresp;
  logic         m_axi_bvalid;
  logic         m_axi_bready;

  logic [31:0]  m_axi_araddr;
  logic [7:0]   m_axi_arlen;
  logic [2:0]   m_axi_arsize;
  logic [1:0]   m_axi_arburst;
  logic         m_axi_arvalid;
  logic         m_axi_arready;
  logic [31:0]  m_axi_rdata;
  logic [1:0]   m_axi_rresp;
  logic         m_axi_rlast;
  logic         m_axi_rvalid;
  logic         m_axi_rready;

  // -------------------------------------------------------------------------
  // AXI Interface Instantiations
  // -------------------------------------------------------------------------
  axi_lite_if axi_lite_if_inst (.clk(clk_i), .rst_n(rst_ni));
  axi4_if     axi4_if_inst     (.clk(clk_i), .rst_n(rst_ni));

  // Connect AXI-Lite signals from DUT to interface (DUT outputs)
  assign axi_lite_if_inst.awvalid = s_axil_awvalid;
  assign axi_lite_if_inst.awready = s_axil_awready;
  assign axi_lite_if_inst.wvalid  = s_axil_wvalid;
  assign axi_lite_if_inst.wready  = s_axil_wready;
  assign axi_lite_if_inst.bresp   = s_axil_bresp;
  assign axi_lite_if_inst.bvalid  = s_axil_bvalid;
  assign axi_lite_if_inst.arvalid = s_axil_arvalid;
  assign axi_lite_if_inst.arready = s_axil_arready;
  assign axi_lite_if_inst.rdata   = s_axil_rdata;
  assign axi_lite_if_inst.rresp   = s_axil_rresp;
  assign axi_lite_if_inst.rvalid  = s_axil_rvalid;

  // Connect AXI4 signals from DUT to memory (DUT outputs)
  assign axi4_if_inst.awaddr  = m_axi_awaddr;
  assign axi4_if_inst.awlen   = m_axi_awlen;
  assign axi4_if_inst.awsize  = m_axi_awsize;
  assign axi4_if_inst.awburst = m_axi_awburst;
  assign axi4_if_inst.awvalid = m_axi_awvalid;
  assign axi4_if_inst.awready = m_axi_awready;
  assign axi4_if_inst.wdata   = m_axi_wdata;
  assign axi4_if_inst.wstrb   = m_axi_wstrb;
  assign axi4_if_inst.wlast   = m_axi_wlast;
  assign axi4_if_inst.wvalid  = m_axi_wvalid;
  assign axi4_if_inst.wready  = m_axi_wready;
  assign axi4_if_inst.bresp   = m_axi_bresp;
  assign axi4_if_inst.bvalid  = m_axi_bvalid;
  assign axi4_if_inst.araddr  = m_axi_araddr;
  assign axi4_if_inst.arlen   = m_axi_arlen;
  assign axi4_if_inst.arsize  = m_axi_arsize;
  assign axi4_if_inst.arburst = m_axi_arburst;
  assign axi4_if_inst.arvalid = m_axi_arvalid;
  assign axi4_if_inst.arready = m_axi_arready;
  assign axi4_if_inst.rdata   = m_axi_rdata;
  assign axi4_if_inst.rresp   = m_axi_rresp;
  assign axi4_if_inst.rlast   = m_axi_rlast;
  assign axi4_if_inst.rvalid  = m_axi_rvalid;

  // DUT instantiation
  ita i_ita (
    .clk_i             (clk_i               ),
    .rst_ni            (rst_ni              ),
    .s_axil_awaddr     (s_axil_awaddr       ),
    .s_axil_awvalid    (s_axil_awvalid      ),
    .s_axil_awready    (s_axil_awready      ),
    .s_axil_wdata      (s_axil_wdata        ),
    .s_axil_wstrb      (s_axil_wstrb        ),
    .s_axil_wvalid     (s_axil_wvalid       ),
    .s_axil_wready     (s_axil_wready       ),
    .s_axil_bresp      (s_axil_bresp        ),
    .s_axil_bvalid     (s_axil_bvalid       ),
    .s_axil_bready     (s_axil_bready       ),
    .s_axil_araddr     (s_axil_araddr       ),
    .s_axil_arvalid    (s_axil_arvalid      ),
    .s_axil_arready    (s_axil_arready      ),
    .s_axil_rdata      (s_axil_rdata        ),
    .s_axil_rresp      (s_axil_rresp        ),
    .s_axil_rvalid     (s_axil_rvalid       ),
    .s_axil_rready     (s_axil_rready       ),
    .m_axi_awaddr      (m_axi_awaddr        ),
    .m_axi_awlen       (m_axi_awlen         ),
    .m_axi_awsize      (m_axi_awsize        ),
    .m_axi_awburst     (m_axi_awburst       ),
    .m_axi_awvalid     (m_axi_awvalid       ),
    .m_axi_awready     (m_axi_awready       ),
    .m_axi_wdata       (m_axi_wdata         ),
    .m_axi_wstrb       (m_axi_wstrb         ),
    .m_axi_wlast       (m_axi_wlast         ),
    .m_axi_wvalid      (m_axi_wvalid        ),
    .m_axi_wready      (m_axi_wready        ),
    .m_axi_bresp       (m_axi_bresp         ),
    .m_axi_bvalid      (m_axi_bvalid        ),
    .m_axi_bready      (m_axi_bready        ),
    .m_axi_araddr      (m_axi_araddr        ),
    .m_axi_arlen       (m_axi_arlen         ),
    .m_axi_arsize      (m_axi_arsize        ),
    .m_axi_arburst     (m_axi_arburst       ),
    .m_axi_arvalid     (m_axi_arvalid       ),
    .m_axi_arready     (m_axi_arready       ),
    .m_axi_rdata       (m_axi_rdata         ),
    .m_axi_rresp       (m_axi_rresp         ),
    .m_axi_rlast       (m_axi_rlast         ),
    .m_axi_rvalid      (m_axi_rvalid        ),
    .m_axi_rready      (m_axi_rready        )
  );

  // AXI Memory Model
  axi_memory i_axi_memory (
    .clk_i         (clk_i         ),
    .rst_ni        (rst_ni        ),
    .awaddr_i      (m_axi_awaddr  ),
    .awlen_i       (m_axi_awlen   ),
    .awsize_i      (m_axi_awsize  ),
    .awburst_i     (m_axi_awburst ),
    .awvalid_i     (m_axi_awvalid ),
    .awready_o     (m_axi_awready ),
    .wdata_i       (m_axi_wdata   ),
    .wstrb_i       (m_axi_wstrb   ),
    .wlast_i       (m_axi_wlast   ),
    .wvalid_i      (m_axi_wvalid  ),
    .wready_o      (m_axi_wready  ),
    .bresp_o       (m_axi_bresp   ),
    .bvalid_o      (m_axi_bvalid  ),
    .bready_i      (m_axi_bready  ),
    .araddr_i      (m_axi_araddr  ),
    .arlen_i       (m_axi_arlen   ),
    .arsize_i      (m_axi_arsize  ),
    .arburst_i     (m_axi_arburst ),
    .arvalid_i     (m_axi_arvalid ),
    .arready_o     (m_axi_arready ),
    .rdata_o       (m_axi_rdata   ),
    .rresp_o       (m_axi_rresp   ),
    .rlast_o       (m_axi_rlast   ),
    .rvalid_o      (m_axi_rvalid  ),
    .rready_i      (m_axi_rready  )
  );

  // Coverage and Assertions Module
  ita_coverage_assertions i_coverage_assertions (
    .clk_i             (clk_i               ),
    .rst_ni            (rst_ni              ),
    .s_axil_awaddr     (s_axil_awaddr       ),
    .s_axil_awvalid    (s_axil_awvalid      ),
    .s_axil_awready    (s_axil_awready      ),
    .s_axil_wdata      (s_axil_wdata        ),
    .s_axil_wstrb      (s_axil_wstrb        ),
    .s_axil_wvalid     (s_axil_wvalid       ),
    .s_axil_wready     (s_axil_wready       ),
    .s_axil_bresp      (s_axil_bresp        ),
    .s_axil_bvalid     (s_axil_bvalid       ),
    .s_axil_bready     (s_axil_bready       ),
    .s_axil_araddr     (s_axil_araddr       ),
    .s_axil_arvalid    (s_axil_arvalid      ),
    .s_axil_arready    (s_axil_arready      ),
    .s_axil_rdata      (s_axil_rdata        ),
    .s_axil_rresp      (s_axil_rresp        ),
    .s_axil_rvalid     (s_axil_rvalid       ),
    .s_axil_rready     (s_axil_rready       ),
    .m_axi_awaddr      (m_axi_awaddr        ),
    .m_axi_awlen       (m_axi_awlen         ),
    .m_axi_awsize      (m_axi_awsize        ),
    .m_axi_awburst     (m_axi_awburst       ),
    .m_axi_awvalid     (m_axi_awvalid       ),
    .m_axi_awready     (m_axi_awready       ),
    .m_axi_wdata       (m_axi_wdata         ),
    .m_axi_wstrb       (m_axi_wstrb         ),
    .m_axi_wlast       (m_axi_wlast         ),
    .m_axi_wvalid      (m_axi_wvalid        ),
    .m_axi_wready      (m_axi_wready        ),
    .m_axi_bresp       (m_axi_bresp         ),
    .m_axi_bvalid      (m_axi_bvalid        ),
    .m_axi_bready      (m_axi_bready        ),
    .m_axi_araddr      (m_axi_araddr        ),
    .m_axi_arlen       (m_axi_arlen         ),
    .m_axi_arsize      (m_axi_arsize        ),
    .m_axi_arburst     (m_axi_arburst       ),
    .m_axi_arvalid     (m_axi_arvalid       ),
    .m_axi_arready     (m_axi_arready       ),
    .m_axi_rdata       (m_axi_rdata         ),
    .m_axi_rresp       (m_axi_rresp         ),
    .m_axi_rlast       (m_axi_rlast         ),
    .m_axi_rvalid      (m_axi_rvalid        ),
    .m_axi_rready      (m_axi_rready        ),
    .step              (i_ita.i_controller.step_o),
    .calc_en           (i_ita.i_controller.calc_en_o),
    .first_inner_tile  (i_ita.i_controller.first_inner_tile_o),
    .last_inner_tile   (i_ita.i_controller.last_inner_tile_o),
    .layer             (i_ita.ctrl_reg.layer),
    .activation        (i_ita.ctrl_reg.activation),
    .busy_o            (i_ita.i_controller.busy_o),
    .fifo_full         (i_ita.fifo_full),
    .fifo_empty        (i_ita.fifo_empty),
    .fifo_usage        (i_ita.fifo_usage),
    .inp_valid_i       (i_ita.i_mem_master.inp_valid_o),
    .inp_ready_o       (i_ita.i_controller.inp_ready_o),
    .weight_valid      (i_ita.i_weight_controller.weight_valid_o),
    .weight_ready      (i_ita.i_weight_controller.weight_ready_i),
    .bias_valid_i      (i_ita.i_mem_master.inp_bias_valid_o),
    .bias_ready_o      (i_ita.i_controller.bias_ready_o),
    .valid_o           (i_ita.valid_o),
    .output_ready_o    (i_ita.output_ready_o)
  );

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5ns clk_i = ~clk_i;
  end

  // Reset generation
  initial begin
    rst_ni = 0;
    #100ns;
    rst_ni = 1;
  end

  // UVM test execution
  initial begin
    // Run UVM test
    run_test();
  end

  // -------------------------------------------------------------------------
  // Set virtual interfaces in UVM config_db
  // This makes them available to the test and agents
  // -------------------------------------------------------------------------
  initial begin
    // Wait for reset to complete
    #100ns;
    #10ns;  // Small delay to ensure UVM is ready
    
    // Set the interfaces in config_db for UVM test
    uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.axi_lite_master", "axi_lite_vif", axi_lite_if_inst);
    uvm_config_db#(virtual axi4_if)::set(null, "uvm_test_top.env.axi4_master", "axi4_vif", axi4_if_inst);
  end

endmodule

`endif

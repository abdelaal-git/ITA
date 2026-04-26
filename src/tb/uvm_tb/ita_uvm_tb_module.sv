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

  // -------------------------------------------------------------------------
  // AXI Interface Instantiations
  // -------------------------------------------------------------------------
  axi_lite_if axi_lite_if_inst (.clk(clk_i), .rst_n(rst_ni));
  axi4_if     axi4_if_inst     (.clk(clk_i), .rst_n(rst_ni));

  // DUT instantiation
  ita i_ita (
    .clk_i             (clk_i               ),
    .rst_ni            (rst_ni              ),
    .s_axil_awaddr     (axi_lite_if_inst.awaddr       ),
    .s_axil_awvalid    (axi_lite_if_inst.awvalid      ),
    .s_axil_awready    (axi_lite_if_inst.awready      ),
    .s_axil_wdata      (axi_lite_if_inst.wdata        ),
    .s_axil_wstrb      (axi_lite_if_inst.wstrb        ),
    .s_axil_wvalid     (axi_lite_if_inst.wvalid       ),
    .s_axil_wready     (axi_lite_if_inst.wready       ),
    .s_axil_bresp      (axi_lite_if_inst.bresp        ),
    .s_axil_bvalid     (axi_lite_if_inst.bvalid       ),
    .s_axil_bready     (axi_lite_if_inst.bready       ),
    .s_axil_araddr     (axi_lite_if_inst.araddr       ),
    .s_axil_arvalid    (axi_lite_if_inst.arvalid      ),
    .s_axil_arready    (axi_lite_if_inst.arready      ),
    .s_axil_rdata      (axi_lite_if_inst.rdata        ),
    .s_axil_rresp      (axi_lite_if_inst.rresp        ),
    .s_axil_rvalid     (axi_lite_if_inst.rvalid       ),
    .s_axil_rready     (axi_lite_if_inst.rready       ),
    .m_axi_awaddr      (axi4_if_inst.awaddr        ),
    .m_axi_awlen       (axi4_if_inst.awlen         ),
    .m_axi_awsize      (axi4_if_inst.awsize        ),
    .m_axi_awburst     (axi4_if_inst.awburst       ),
    .m_axi_awvalid     (axi4_if_inst.awvalid       ),
    .m_axi_awready     (axi4_if_inst.awready       ),
    .m_axi_wdata       (axi4_if_inst.wdata         ),
    .m_axi_wstrb       (axi4_if_inst.wstrb         ),
    .m_axi_wlast       (axi4_if_inst.wlast         ),
    .m_axi_wvalid      (axi4_if_inst.wvalid        ),
    .m_axi_wready      (axi4_if_inst.wready        ),
    .m_axi_bresp       (axi4_if_inst.bresp         ),
    .m_axi_bvalid      (axi4_if_inst.bvalid        ),
    .m_axi_bready      (axi4_if_inst.bready        ),
    .m_axi_araddr      (axi4_if_inst.araddr        ),
    .m_axi_arlen       (axi4_if_inst.arlen         ),
    .m_axi_arsize      (axi4_if_inst.arsize        ),
    .m_axi_arburst     (axi4_if_inst.arburst       ),
    .m_axi_arvalid     (axi4_if_inst.arvalid       ),
    .m_axi_arready     (axi4_if_inst.arready       ),
    .m_axi_rdata       (axi4_if_inst.rdata         ),
    .m_axi_rresp       (axi4_if_inst.rresp         ),
    .m_axi_rlast       (axi4_if_inst.rlast         ),
    .m_axi_rvalid      (axi4_if_inst.rvalid        ),
    .m_axi_rready      (axi4_if_inst.rready        )
  );

  // AXI Memory Model
  axi_memory i_axi_memory (
    .clk_i         (clk_i         ),
    .rst_ni        (rst_ni        ),
    .awaddr_i      (axi4_if_inst.awaddr  ),
    .awlen_i       (axi4_if_inst.awlen   ),
    .awsize_i      (axi4_if_inst.awsize  ),
    .awburst_i     (axi4_if_inst.awburst ),
    .awvalid_i     (axi4_if_inst.awvalid ),
    .awready_o     (axi4_if_inst.awready ),
    .wdata_i       (axi4_if_inst.wdata   ),
    .wstrb_i       (axi4_if_inst.wstrb   ),
    .wlast_i       (axi4_if_inst.wlast   ),
    .wvalid_i      (axi4_if_inst.wvalid  ),
    .wready_o      (axi4_if_inst.wready  ),
    .bresp_o       (axi4_if_inst.bresp   ),
    .bvalid_o      (axi4_if_inst.bvalid  ),
    .bready_i      (axi4_if_inst.bready  ),
    .araddr_i      (axi4_if_inst.araddr  ),
    .arlen_i       (axi4_if_inst.arlen   ),
    .arsize_i      (axi4_if_inst.arsize  ),
    .arburst_i     (axi4_if_inst.arburst ),
    .arvalid_i     (axi4_if_inst.arvalid ),
    .arready_o     (axi4_if_inst.arready ),
    .rdata_o       (axi4_if_inst.rdata   ),
    .rresp_o       (axi4_if_inst.rresp   ),
    .rlast_o       (axi4_if_inst.rlast   ),
    .rvalid_o      (axi4_if_inst.rvalid  ),
    .rready_i      (axi4_if_inst.rready  )
  );

  // Coverage and Assertions Module
  ita_coverage_assertions i_coverage_assertions (
    .clk_i             (clk_i               ),
    .rst_ni            (rst_ni              ),
    .s_axil_awaddr     (axi_lite_if_inst.awaddr       ),
    .s_axil_awvalid    (axi_lite_if_inst.awvalid      ),
    .s_axil_awready    (axi_lite_if_inst.awready      ),
    .s_axil_wdata      (axi_lite_if_inst.wdata        ),
    .s_axil_wstrb      (axi_lite_if_inst.wstrb        ),
    .s_axil_wvalid     (axi_lite_if_inst.wvalid       ),
    .s_axil_wready     (axi_lite_if_inst.wready       ),
    .s_axil_bresp      (axi_lite_if_inst.bresp        ),
    .s_axil_bvalid     (axi_lite_if_inst.bvalid       ),
    .s_axil_bready     (axi_lite_if_inst.bready       ),
    .s_axil_araddr     (axi_lite_if_inst.araddr       ),
    .s_axil_arvalid    (axi_lite_if_inst.arvalid      ),
    .s_axil_arready    (axi_lite_if_inst.arready      ),
    .s_axil_rdata      (axi_lite_if_inst.rdata        ),
    .s_axil_rresp      (axi_lite_if_inst.rresp        ),
    .s_axil_rvalid     (axi_lite_if_inst.rvalid       ),
    .s_axil_rready     (axi_lite_if_inst.rready       ),
    .m_axi_awaddr      (axi4_if_inst.awaddr        ),
    .m_axi_awlen       (axi4_if_inst.awlen         ),
    .m_axi_awsize      (axi4_if_inst.awsize        ),
    .m_axi_awburst     (axi4_if_inst.awburst       ),
    .m_axi_awvalid     (axi4_if_inst.awvalid       ),
    .m_axi_awready     (axi4_if_inst.awready       ),
    .m_axi_wdata       (axi4_if_inst.wdata         ),
    .m_axi_wstrb       (axi4_if_inst.wstrb         ),
    .m_axi_wlast       (axi4_if_inst.wlast         ),
    .m_axi_wvalid      (axi4_if_inst.wvalid        ),
    .m_axi_wready      (axi4_if_inst.wready        ),
    .m_axi_bresp       (axi4_if_inst.bresp         ),
    .m_axi_bvalid      (axi4_if_inst.bvalid        ),
    .m_axi_bready      (axi4_if_inst.bready        ),
    .m_axi_araddr      (axi4_if_inst.araddr        ),
    .m_axi_arlen       (axi4_if_inst.arlen         ),
    .m_axi_arsize      (axi4_if_inst.arsize        ),
    .m_axi_arburst     (axi4_if_inst.arburst       ),
    .m_axi_arvalid     (axi4_if_inst.arvalid       ),
    .m_axi_arready     (axi4_if_inst.arready       ),
    .m_axi_rdata       (axi4_if_inst.rdata         ),
    .m_axi_rresp       (axi4_if_inst.rresp         ),
    .m_axi_rlast       (axi4_if_inst.rlast         ),
    .m_axi_rvalid      (axi4_if_inst.rvalid        ),
    .m_axi_rready      (axi4_if_inst.rready        ),
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
    $fsdbDumpfile("sim.fsdb");
    $fsdbDumpvars(0, ita_uvm_tb, "+all");
    $fsdbDumpMDA;
    // Set the interfaces in config_db for UVM test
    uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.axi_lite_master*", "axi_lite_vif", axi_lite_if_inst);
    uvm_config_db#(virtual axi4_if)::set(null, "uvm_test_top.env.axi4_master*", "axi4_vif", axi4_if_inst);
  end

endmodule

`endif

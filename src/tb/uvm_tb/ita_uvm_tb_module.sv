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
    .output_ready_o    (i_ita.i_mem_master.output_ready_i)
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

endmodule

`endif

// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/**
  ITA Control Registers Module with AXI4-Lite interface.
*/

module ita_ctrl_regs
  import ita_package::*;
(
  input  logic         clk_i             ,
  input  logic         rst_ni            ,
  // AXI4-Lite slave interface for control registers
  input  logic [31:0]  s_axil_awaddr     ,
  input  logic         s_axil_awvalid    ,
  output logic         s_axil_awready    ,
  input  logic [31:0]  s_axil_wdata      ,
  input  logic [3:0]   s_axil_wstrb      ,
  input  logic         s_axil_wvalid     ,
  output logic         s_axil_wready     ,
  output logic [1:0]   s_axil_bresp      ,
  output logic         s_axil_bvalid     ,
  input  logic         s_axil_bready     ,
  input  logic [31:0]  s_axil_araddr     ,
  input  logic         s_axil_arvalid    ,
  output logic         s_axil_arready    ,
  output logic [31:0]  s_axil_rdata      ,
  output logic [1:0]   s_axil_rresp      ,
  output logic         s_axil_rvalid     ,
  input  logic         s_axil_rready     ,
  // Control output
  output ctrl_t        ctrl_reg_o,
  output logic [31:0]  mem_input_base_addr_o,
  output logic [31:0]  mem_weight_base_addr_o,
  output logic [31:0]  mem_bias_base_addr_o,
  output logic [31:0]  mem_output_base_addr_o
);

  // Control registers
  logic [31:0] ctrl_reg_file [0:15];
  logic [383:0] flat_ctrl;
  assign flat_ctrl = {ctrl_reg_file[11], ctrl_reg_file[10], ctrl_reg_file[9], ctrl_reg_file[8], ctrl_reg_file[7], ctrl_reg_file[6], ctrl_reg_file[5], ctrl_reg_file[4], ctrl_reg_file[3], ctrl_reg_file[2], ctrl_reg_file[1], ctrl_reg_file[0]};
  assign ctrl_reg_o = flat_ctrl[380:0];
  assign mem_input_base_addr_o  = ctrl_reg_file[12];
  assign mem_weight_base_addr_o = ctrl_reg_file[13];
  assign mem_bias_base_addr_o   = ctrl_reg_file[14];
  assign mem_output_base_addr_o = ctrl_reg_file[15];

  // AXI signals
  logic [31:0] awaddr;
  logic        awready;
  logic        wready;
  logic [1:0]  bresp;
  logic        bvalid;
  logic [31:0] araddr;
  logic        arready;
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  assign s_axil_awready = awready;
  assign s_axil_wready = wready;
  assign s_axil_bresp = bresp;
  assign s_axil_bvalid = bvalid;
  assign s_axil_arready = arready;
  assign s_axil_rdata = rdata;
  assign s_axil_rresp = rresp;
  assign s_axil_rvalid = rvalid;

  // AXI write address
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      awready <= 1'b0;
      awaddr <= 32'b0;
    end else begin
      if (s_axil_awvalid && !awready) begin
        awready <= 1'b1;
        awaddr <= s_axil_awaddr;
      end else begin
        awready <= 1'b0;
      end
    end
  end

  // AXI write data
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      wready <= 1'b0;
    end else begin
      if (s_axil_wvalid && !wready) begin
        wready <= 1'b1;
      end else begin
        wready <= 1'b0;
      end
    end
  end

  // AXI write response
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      bvalid <= 1'b0;
      bresp <= 2'b00;
    end else begin
      if (awready && wready) begin
        bvalid <= 1'b1;
        if (awaddr[31:2] < 16) begin
          bresp <= 2'b00; // OKAY
          // update register
          for (int i = 0; i < 4; i++) begin
            if (s_axil_wstrb[i]) begin
              ctrl_reg_file[awaddr[31:2]][i*8 +: 8] <= s_axil_wdata[i*8 +: 8];
            end
          end
        end else begin
          bresp <= 2'b10; // SLVERR
        end
      end else if (s_axil_bready && bvalid) begin
        bvalid <= 1'b0;
      end
    end
  end

  // AXI read address
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      arready <= 1'b0;
      araddr <= 32'b0;
    end else begin
      if (s_axil_arvalid && !arready) begin
        arready <= 1'b1;
        araddr <= s_axil_araddr;
      end else begin
        arready <= 1'b0;
      end
    end
  end

  // AXI read data
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid <= 1'b0;
      rdata <= 32'b0;
      rresp <= 2'b00;
    end else begin
      if (arready) begin
        rvalid <= 1'b1;
        if (araddr[31:2] < 16) begin
          rdata <= ctrl_reg_file[araddr[31:2]];
          rresp <= 2'b00;
        end else begin
          rdata <= 32'b0;
          rresp <= 2'b10;
        end
      end else if (s_axil_rready && rvalid) begin
        rvalid <= 1'b0;
      end
    end
  end

  // Initialize registers
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < 16; i++) begin
        ctrl_reg_file[i] <= 32'b0;
      end
    end
  end

endmodule
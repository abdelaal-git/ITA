// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/**
  ITA Control Registers Module with AXI4-Lite interface.
*/
import ita_package::*;
module ita_ctrl_regs #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int NUM_REGS   = 16   // 16 registers (0 to 15)
)
  
(
  input  logic                    clk_i,
  input  logic                    rst_ni,

  // AXI4-Lite Slave Interface
  input  logic [ADDR_WIDTH-1:0]   s_axil_awaddr,
  input  logic                    s_axil_awvalid,
  output logic                    s_axil_awready,

  input  logic [DATA_WIDTH-1:0]   s_axil_wdata,
  input  logic [DATA_WIDTH/8-1:0] s_axil_wstrb,
  input  logic                    s_axil_wvalid,
  output logic                    s_axil_wready,

  output logic [1:0]              s_axil_bresp,
  output logic                    s_axil_bvalid,
  input  logic                    s_axil_bready,

  input  logic [ADDR_WIDTH-1:0]   s_axil_araddr,
  input  logic                    s_axil_arvalid,
  output logic                    s_axil_arready,

  output logic [DATA_WIDTH-1:0]   s_axil_rdata,
  output logic [1:0]              s_axil_rresp,
  output logic                    s_axil_rvalid,
  input  logic                    s_axil_rready,
  // Control output
  output ctrl_t        ctrl_reg_o,
  output logic [ADDR_WIDTH-1:0]  mem_input_base_addr_o,
  output logic [ADDR_WIDTH-1:0]  mem_weight_base_addr_o,
  output logic [ADDR_WIDTH-1:0]  mem_bias_base_addr_o,
  output logic [ADDR_WIDTH-1:0]  mem_output_base_addr_o
);
// Latch signals for write
  logic [ADDR_WIDTH-1:0]   awaddr_latched;
  logic [DATA_WIDTH-1:0]   wdata_latched;
  logic [DATA_WIDTH/8-1:0] wstrb_latched;
  logic aw_done;
  logic w_done;


  // Control registers
  logic [DATA_WIDTH-1:0] ctrl_reg_file [0:NUM_REGS-1];
  logic [383:0] flat_ctrl;
  assign flat_ctrl = {ctrl_reg_file[11], ctrl_reg_file[10], ctrl_reg_file[9], ctrl_reg_file[8], ctrl_reg_file[7], ctrl_reg_file[6], ctrl_reg_file[5], ctrl_reg_file[4], ctrl_reg_file[3], ctrl_reg_file[2], ctrl_reg_file[1], ctrl_reg_file[0]};
  assign ctrl_reg_o = flat_ctrl[380:0];
  assign mem_input_base_addr_o  = ctrl_reg_file[12];
  assign mem_weight_base_addr_o = ctrl_reg_file[13];
  assign mem_bias_base_addr_o   = ctrl_reg_file[14];
  assign mem_output_base_addr_o = ctrl_reg_file[15];
  
  // ========================================
  // Write Address Channel
  // ========================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          s_axil_awready  <= 1'b0;
          awaddr_latched  <= '0;
          aw_done         <= 1'b0;
      end else begin
          // Accept address when no pending transaction
          if (s_axil_awvalid && !aw_done) begin
              s_axil_awready <= 1'b1;
              awaddr_latched <= s_axil_awaddr;
              aw_done        <= 1'b1;
          end else begin
              s_axil_awready <= 1'b0;
          end

          // Clear when response is accepted
          if (s_axil_bready && s_axil_bvalid) begin
              aw_done <= 1'b0;
          end
      end
  end

 // ========================================
  // Write Data Channel
  // ========================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          s_axil_wready   <= 1'b0;
          wdata_latched   <= '0;
          wstrb_latched   <= '0;
          w_done          <= 1'b0;
      end else begin
          if (s_axil_wvalid && !w_done) begin
              s_axil_wready  <= 1'b1;
              wdata_latched  <= s_axil_wdata;
              wstrb_latched  <= s_axil_wstrb;
              w_done         <= 1'b1;
          end else begin
              s_axil_wready <= 1'b0;
          end

          if (s_axil_bready && s_axil_bvalid) begin
              w_done <= 1'b0;
          end
      end
  end

  // ========================================
  // Write Response + Register Update
  // ========================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          s_axil_bvalid <= 1'b0;
          s_axil_bresp  <= 2'b00;
          for (int i = 0; i < NUM_REGS; i++) begin
              ctrl_reg_file[i] <= '0;
          end
      end else begin
          // Start response only when both channels are done and no pending response
          if (aw_done && w_done && !s_axil_bvalid) begin
              s_axil_bvalid <= 1'b1;

              if (awaddr_latched[ADDR_WIDTH-1:2] < NUM_REGS) begin
                  s_axil_bresp <= 2'b00; // OKAY

                  // Byte-wise write using WSTRB
                  for (int i = 0; i < DATA_WIDTH/8; i++) begin
                      if (wstrb_latched[i]) begin
                          ctrl_reg_file[awaddr_latched[ADDR_WIDTH-1:2]][i*8 +: 8] <= wdata_latched[i*8 +: 8];
                      end
                  end
              end else begin
                  s_axil_bresp <= 2'b10; // SLVERR
              end
          end 
          // Clear response when master accepts it
          else if (s_axil_bready && s_axil_bvalid) begin
              s_axil_bvalid <= 1'b0;
          end
      end
  end

  // ========================================
  // Read Address Channel
  // ========================================
  logic [ADDR_WIDTH-1:0] araddr_latched;
  logic                  ar_done;

  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          s_axil_arready <= 1'b0;
          araddr_latched <= '0;
          ar_done        <= 1'b0;
      end else begin
          if (s_axil_arvalid && !ar_done) begin
              s_axil_arready <= 1'b1;
              araddr_latched <= s_axil_araddr;
              ar_done        <= 1'b1;
          end else begin
              s_axil_arready <= 1'b0;
          end

          if (s_axil_rready && s_axil_rvalid) begin
              ar_done <= 1'b0;
          end
      end
  end

  // ========================================
  // Read Data Channel
  // ========================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          s_axil_rvalid <= 1'b0;
          s_axil_rdata  <= '0;
          s_axil_rresp  <= 2'b00;
      end else begin
          if (ar_done && !s_axil_rvalid) begin
              s_axil_rvalid <= 1'b1;

              if (araddr_latched[ADDR_WIDTH-1:2] < NUM_REGS) begin
                  s_axil_rdata <= ctrl_reg_file[araddr_latched[ADDR_WIDTH-1:2]];
                  s_axil_rresp <= 2'b00; // OKAY
              end else begin
                  s_axil_rdata <= '0;
                  s_axil_rresp <= 2'b10; // SLVERR
              end
          end 
          else if (s_axil_rready && s_axil_rvalid) begin
              s_axil_rvalid <= 1'b0;
          end
      end
  end

endmodule

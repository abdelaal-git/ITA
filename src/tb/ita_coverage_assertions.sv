// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

/**
  ITA Functional Coverage and Assertions
*/

`ifndef ITA_COVERAGE_ASSERTIONS_SV
`define ITA_COVERAGE_ASSERTIONS_SV

module ita_coverage_assertions
  import ita_package::*;
(
  input logic         clk_i,
  input logic         rst_ni,

  // AXI4-Lite slave interface
  input logic [31:0]  s_axil_awaddr,
  input logic         s_axil_awvalid,
  input logic         s_axil_awready,
  input logic [31:0]  s_axil_wdata,
  input logic [3:0]   s_axil_wstrb,
  input logic         s_axil_wvalid,
  input logic         s_axil_wready,
  input logic [1:0]   s_axil_bresp,
  input logic         s_axil_bvalid,
  input logic         s_axil_bready,
  input logic [31:0]  s_axil_araddr,
  input logic         s_axil_arvalid,
  input logic         s_axil_arready,
  input logic [31:0]  s_axil_rdata,
  input logic [1:0]   s_axil_rresp,
  input logic         s_axil_rvalid,
  input logic         s_axil_rready,

  // AXI4 master interface
  input logic [31:0]  m_axi_awaddr,
  input logic [7:0]   m_axi_awlen,
  input logic [2:0]   m_axi_awsize,
  input logic [1:0]   m_axi_awburst,
  input logic         m_axi_awvalid,
  input logic         m_axi_awready,
  input logic [31:0]  m_axi_wdata,
  input logic [3:0]   m_axi_wstrb,
  input logic         m_axi_wlast,
  input logic         m_axi_wvalid,
  input logic         m_axi_wready,
  input logic [1:0]   m_axi_bresp,
  input logic         m_axi_bvalid,
  input logic         m_axi_bready,
  input logic [31:0]  m_axi_araddr,
  input logic [7:0]   m_axi_arlen,
  input logic [2:0]   m_axi_arsize,
  input logic [1:0]   m_axi_arburst,
  input logic         m_axi_arvalid,
  input logic         m_axi_arready,
  input logic [31:0]  m_axi_rdata,
  input logic [1:0]   m_axi_rresp,
  input logic         m_axi_rlast,
  input logic         m_axi_rvalid,
  input logic         m_axi_rready,

  // Internal signals from ITA module
  input step_e        step,
  input logic         calc_en,
  input logic         first_inner_tile,
  input logic         last_inner_tile,
  input layer_e       layer,
  input activation_e  activation,
  input logic         busy_o,
  input logic         fifo_full,
  input logic         fifo_empty,
  input fifo_usage_t  fifo_usage,
  input logic         inp_valid_i,
  input logic         inp_ready_o,
  input logic         weight_valid,
  input logic         weight_ready,
  input logic         bias_valid_i,
  input logic         bias_ready_o,
  input logic         valid_o,
  input logic         output_ready_o
);

// =============================================================================
// FUNCTIONAL COVERAGE GROUPS
// =============================================================================

// State machine coverage
covergroup cg_state_machine @(posedge clk_i);
  option.per_instance = 1;
  option.name = "state_machine_coverage";

  cp_state: coverpoint step {
    bins idle     = {Idle};
    bins q_step   = {Q};
    bins k_step   = {K};
    bins v_step   = {V};
    bins qk_step  = {QK};
    bins av_step  = {AV};
    bins ow_step  = {OW};
    bins f1_step  = {F1};
    bins f2_step  = {F2};
    bins matmul   = {MatMul};
  }

  cp_state_transitions: coverpoint step {
    bins idle_to_q     = (Idle => Q);
    bins q_to_k        = (Q => K);
    bins k_to_v        = (K => V);
    bins v_to_qk       = (V => QK);
    bins qk_to_av      = (QK => AV);
    bins av_to_ow      = (AV => OW);
    bins av_to_qk      = (AV => QK); // For softmax iterations
    bins ow_to_idle    = (OW => Idle);
    bins idle_to_f1    = (Idle => F1);
    bins f1_to_f2      = (F1 => F2);
    bins f2_to_idle    = (F2 => Idle);
    bins idle_to_matmul = (Idle => MatMul);
    bins matmul_to_idle = (MatMul => Idle);
    bins idle_to_qk    = (Idle => QK); // SingleAttention
    bins av_to_idle    = (AV => Idle); // SingleAttention
  }
endgroup

// Layer and activation coverage
covergroup cg_layer_activation @(posedge clk_i);
  option.per_instance = 1;
  option.name = "layer_activation_coverage";

  cp_layer: coverpoint layer {
    bins attention      = {Attention};
    bins feedforward    = {Feedforward};
    bins linear         = {Linear};
    bins single_attention = {SingleAttention};
  }

  cp_activation: coverpoint activation {
    bins identity = {Identity};
    bins gelu     = {Gelu};
    bins relu     = {Relu};
  }

  cp_layer_activation_cross: cross cp_layer, cp_activation {
    ignore_bins attention_identity = binsof(cp_layer.attention) && binsof(cp_activation.identity);
    ignore_bins linear_gelu = binsof(cp_layer.linear) && binsof(cp_activation.gelu);
    ignore_bins linear_relu = binsof(cp_layer.linear) && binsof(cp_activation.relu);
  }
endgroup

// FIFO coverage
covergroup cg_fifo_usage @(posedge clk_i);
  option.per_instance = 1;
  option.name = "fifo_usage_coverage";

  cp_fifo_level: coverpoint fifo_usage {
    bins empty = {0};
    bins low   = {[1:3]};
    bins mid   = {[4:8]};
    bins high  = {[9:FifoDepth-1]};
    bins full  = {FifoDepth};
  }

  cp_fifo_full: coverpoint fifo_full {
    bins not_full = {0};
    bins full     = {1};
  }

  cp_fifo_empty: coverpoint fifo_empty {
    bins not_empty = {0};
    bins empty     = {1};
  }

  cp_fifo_full_empty_cross: cross cp_fifo_full, cp_fifo_empty {
    bins normal = binsof(cp_fifo_full.not_full) && binsof(cp_fifo_empty.not_empty);
    bins full_only = binsof(cp_fifo_full.full) && binsof(cp_fifo_empty.not_empty);
    bins empty_only = binsof(cp_fifo_full.not_full) && binsof(cp_fifo_empty.empty);
    illegal_bins both = binsof(cp_fifo_full.full) && binsof(cp_fifo_empty.empty);
  }
endgroup

// AXI4-Lite control interface coverage
covergroup cg_axil_protocol @(posedge clk_i);
  option.per_instance = 1;
  option.name = "axil_protocol_coverage";

  cp_awvalid_awready: coverpoint {s_axil_awvalid, s_axil_awready} {
    bins no_transfer = {2'b00};
    bins aw_stall    = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_wvalid_wready: coverpoint {s_axil_wvalid, s_axil_wready} {
    bins no_transfer = {2'b00};
    bins w_stall     = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_bvalid_bready: coverpoint {s_axil_bvalid, s_axil_bready} {
    bins no_transfer = {2'b00};
    bins b_stall     = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_arvalid_arready: coverpoint {s_axil_arvalid, s_axil_arready} {
    bins no_transfer = {2'b00};
    bins ar_stall    = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_rvalid_rready: coverpoint {s_axil_rvalid, s_axil_rready} {
    bins no_transfer = {2'b00};
    bins r_stall     = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_axil_bresp: coverpoint s_axil_bresp {
    bins okay  = {2'b00};
    bins exokay = {2'b01};
    bins slverr = {2'b10};
    bins decerr = {2'b11};
  }

  cp_axil_rresp: coverpoint s_axil_rresp {
    bins okay  = {2'b00};
    bins exokay = {2'b01};
    bins slverr = {2'b10};
    bins decerr = {2'b11};
  }
endgroup

// AXI4 memory interface coverage
covergroup cg_axi4_protocol @(posedge clk_i);
  option.per_instance = 1;
  option.name = "axi4_protocol_coverage";

  cp_awburst: coverpoint m_axi_awburst {
    bins fixed    = {2'b00};
    bins incr     = {2'b01};
    bins wrap     = {2'b10};
    bins reserved = {2'b11};
  }

  cp_arburst: coverpoint m_axi_arburst {
    bins fixed    = {2'b00};
    bins incr     = {2'b01};
    bins wrap     = {2'b10};
    bins reserved = {2'b11};
  }

  cp_awlen: coverpoint m_axi_awlen {
    bins single = {0};
    bins burst_2_3 = {[1:3]};
    bins burst_4_7 = {[4:7]};
    bins burst_8_15 = {[8:15]};
    bins burst_16_31 = {[16:31]};
    bins burst_32_63 = {[32:63]};
    bins burst_64_127 = {[64:127]};
    bins burst_128_255 = {[128:255]};
  }

  cp_arlen: coverpoint m_axi_arlen {
    bins single = {0};
    bins burst_2_3 = {[1:3]};
    bins burst_4_7 = {[4:7]};
    bins burst_8_15 = {[8:15]};
    bins burst_16_31 = {[16:31]};
    bins burst_32_63 = {[32:63]};
    bins burst_64_127 = {[64:127]};
    bins burst_128_255 = {[128:255]};
  }

  cp_awsize: coverpoint m_axi_awsize {
    bins byte_1   = {0};
    bins byte_2   = {1};
    bins byte_4   = {2};
    bins byte_8   = {3};
    bins byte_16  = {4};
    bins byte_32  = {5};
    bins byte_64  = {6};
    bins byte_128 = {7};
  }

  cp_arsize: coverpoint m_axi_arsize {
    bins byte_1   = {0};
    bins byte_2   = {1};
    bins byte_4   = {2};
    bins byte_8   = {3};
    bins byte_16  = {4};
    bins byte_32  = {5};
    bins byte_64  = {6};
    bins byte_128 = {7};
  }

  cp_bresp: coverpoint m_axi_bresp {
    bins okay  = {2'b00};
    bins exokay = {2'b01};
    bins slverr = {2'b10};
    bins decerr = {2'b11};
  }

  cp_rresp: coverpoint m_axi_rresp {
    bins okay  = {2'b00};
    bins exokay = {2'b01};
    bins slverr = {2'b10};
    bins decerr = {2'b11};
  }
endgroup

// Data flow coverage
covergroup cg_data_flow @(posedge clk_i);
  option.per_instance = 1;
  option.name = "data_flow_coverage";

  cp_calc_en: coverpoint calc_en {
    bins inactive = {0};
    bins active   = {1};
  }

  cp_first_inner_tile: coverpoint first_inner_tile {
    bins not_first = {0};
    bins first     = {1};
  }

  cp_last_inner_tile: coverpoint last_inner_tile {
    bins not_last = {0};
    bins last     = {1};
  }

  cp_busy: coverpoint busy_o {
    bins idle = {0};
    bins busy = {1};
  }

  cp_input_handshake: coverpoint {inp_valid_i, inp_ready_o} {
    bins no_transfer = {2'b00};
    bins stall       = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_weight_handshake: coverpoint {weight_valid, weight_ready} {
    bins no_transfer = {2'b00};
    bins stall       = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_bias_handshake: coverpoint {bias_valid_i, bias_ready_o} {
    bins no_transfer = {2'b00};
    bins stall       = {2'b10};
    bins transfer    = {2'b11};
  }

  cp_output_handshake: coverpoint {valid_o, output_ready_o} {
    bins no_transfer = {2'b00};
    bins stall       = {2'b10};
    bins transfer    = {2'b11};
  }
endgroup

// =============================================================================
// COVERAGE GROUP INSTANCES
// =============================================================================

cg_state_machine      cg_sm;
cg_layer_activation   cg_la;
cg_fifo_usage         cg_fu;
cg_axil_protocol      cg_axil;
cg_axi4_protocol      cg_axi4;
cg_data_flow          cg_df;

// =============================================================================
// ASSERTIONS
// =============================================================================

// AXI4-Lite Protocol Assertions
axil_aw_stable: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  (s_axil_awvalid && !s_axil_awready) |=> $stable(s_axil_awaddr)
) else $error("AXI4-Lite AWADDR not stable during stall");

axil_w_stable: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  (s_axil_wvalid && !s_axil_wready) |=> ($stable(s_axil_wdata) && $stable(s_axil_wstrb))
) else $error("AXI4-Lite WDATA/WSTRB not stable during stall");

axil_ar_stable: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  (s_axil_arvalid && !s_axil_arready) |=> $stable(s_axil_araddr)
) else $error("AXI4-Lite ARADDR not stable during stall");

axil_bresp_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  s_axil_bvalid |-> (s_axil_bresp inside {2'b00, 2'b01, 2'b10})
) else $error("AXI4-Lite BRESP has invalid value");

axil_rresp_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  s_axil_rvalid |-> (s_axil_rresp inside {2'b00, 2'b01, 2'b10})
) else $error("AXI4-Lite RRESP has invalid value");

// AXI4 Protocol Assertions
axi4_awburst_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  m_axi_awvalid |-> (m_axi_awburst inside {2'b00, 2'b01, 2'b10})
) else $error("AXI4 AWBURST has invalid value");

axi4_arburst_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  m_axi_arvalid |-> (m_axi_arburst inside {2'b00, 2'b01, 2'b10})
) else $error("AXI4 ARBURST has invalid value");

axi4_awsize_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  m_axi_awvalid |-> (m_axi_awsize <= 3'd7)
) else $error("AXI4 AWSIZE has invalid value");

axi4_arsize_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  m_axi_arvalid |-> (m_axi_arsize <= 3'd7)
) else $error("AXI4 ARSIZE has invalid value");

axi4_wlast_timing: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  (m_axi_awvalid && m_axi_awready && m_axi_awlen > 0) |=>
  ##[1:$] (m_axi_wvalid && m_axi_wready && m_axi_wlast)
) else $error("AXI4 WLAST not asserted at end of burst");

axi4_rlast_timing: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  (m_axi_arvalid && m_axi_arready && m_axi_arlen > 0) |=>
  ##[1:$] (m_axi_rvalid && m_axi_rready && m_axi_rlast)
) else $error("AXI4 RLAST not asserted at end of burst");

// State Machine Assertions
state_machine_valid_transitions: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  step inside {Idle, Q, K, V, QK, AV, OW, F1, F2, MatMul}
) else $error("Invalid state in state machine");

idle_to_valid_states: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  (step == Idle) && !$stable(step) |->
  (step inside {Q, F1, MatMul, QK})
) else $error("Invalid transition from Idle state");

// FIFO Assertions
fifo_no_overflow: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  fifo_full |-> ##1 !fifo_full // Once full, should not stay full indefinitely
) else $warning("FIFO may be stuck in full state");

fifo_no_underflow: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  fifo_empty |-> ##1 !fifo_empty // Once empty, should not stay empty indefinitely
) else $warning("FIFO may be stuck in empty state");

fifo_full_empty_mutex: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  !(fifo_full && fifo_empty)
) else $error("FIFO cannot be both full and empty");

// Data Flow Assertions
calc_en_implies_inputs_valid: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  calc_en |-> (inp_valid_i && weight_valid && bias_valid_i)
) else $error("calc_en asserted without valid inputs");

busy_implies_calculation: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  busy_o |-> (step != Idle)
) else $error("Busy asserted while in Idle state");

// Pipeline timing assertions
first_last_tile_mutex: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  !(first_inner_tile && last_inner_tile)
) else $error("Tile cannot be both first and last");

// =============================================================================
// COVERAGE SAMPLING
// =============================================================================

initial begin
  cg_sm = new();
  cg_la = new();
  cg_fu = new();
  cg_axil = new();
  cg_axi4 = new();
  cg_df = new();
end

endmodule

`endif
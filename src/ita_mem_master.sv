// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

module ita_mem_master
  import ita_package::*;
(
  input  logic          clk_i,
  input  logic          rst_ni,

  // Memory base pointers from control registers
  input  logic [31:0]   mem_input_base_addr_i,
  input  logic [31:0]   mem_weight_base_addr_i,
  input  logic [31:0]   mem_bias_base_addr_i,
  input  logic [31:0]   mem_output_base_addr_i,

  // AXI4 master interface
  output logic [31:0]  m_axi_awaddr,
  output logic [7:0]   m_axi_awlen,
  output logic [2:0]   m_axi_awsize,
  output logic [1:0]   m_axi_awburst,
  output logic         m_axi_awvalid,
  input  logic         m_axi_awready,
  output logic [31:0]  m_axi_wdata,
  output logic [3:0]   m_axi_wstrb,
  output logic         m_axi_wlast,
  output logic         m_axi_wvalid,
  input  logic         m_axi_wready,
  input  logic [1:0]   m_axi_bresp,
  input  logic         m_axi_bvalid,
  output logic         m_axi_bready,

  output logic [31:0]  m_axi_araddr,
  output logic [7:0]   m_axi_arlen,
  output logic [2:0]   m_axi_arsize,
  output logic [1:0]   m_axi_arburst,
  output logic         m_axi_arvalid,
  input  logic         m_axi_arready,
  input  logic [31:0]  m_axi_rdata,
  input  logic [1:0]   m_axi_rresp,
  input  logic         m_axi_rlast,
  input  logic         m_axi_rvalid,
  output logic         m_axi_rready,

  // Streamed data interfaces
  output logic         inp_valid_o,
  input  logic         inp_ready_i,
  output inp_t         inp_o,

  output logic         inp_weight_valid_o,
  input  logic         inp_weight_ready_i,
  output inp_weight_t  inp_weight_o,

  output logic         inp_bias_valid_o,
  input  logic         inp_bias_ready_i,
  output bias_t        inp_bias_o,

  input  logic         output_valid_i,
  output logic         output_ready_o,
  input  fifo_data_t   output_data_i
);

  localparam int unsigned INP_BITS     = M * WI;
  localparam int unsigned INP_WORDS    = (INP_BITS + 31) / 32;
  localparam int unsigned INP_BYTES    = INP_WORDS * 4;
  localparam int unsigned WEIGHT_BITS  = (N * M / N_WRITE_EN) * WI;
  localparam int unsigned WEIGHT_WORDS = (WEIGHT_BITS + 31) / 32;
  localparam int unsigned WEIGHT_BYTES = WEIGHT_WORDS * 4;
  localparam int unsigned BIAS_BITS    = N * (WO - 2);
  localparam int unsigned BIAS_WORDS   = (BIAS_BITS + 31) / 32;
  localparam int unsigned BIAS_BYTES   = BIAS_WORDS * 4;
  localparam int unsigned OUT_BITS     = N * WI;
  localparam int unsigned OUT_WORDS    = (OUT_BITS + 31) / 32;
  localparam int unsigned OUT_BYTES    = OUT_WORDS * 4;

  typedef enum logic [2:0] {IDLE=0, WRITE_ADDR=1, WRITE_DATA=2, WRITE_RESP=3, READ_ADDR=4, READ_DATA=5} axi_state_e;
  typedef enum logic [2:0] {NONE=0, READ_INP=1, READ_WEIGHT=2, READ_BIAS=3, WRITE_OUT=4} cmd_e;

  axi_state_e state_q, state_d;
  cmd_e       cmd_q, cmd_d;

  logic [31:0] addr_q, addr_d;
  logic [7:0]  beat_q, beat_d;

  logic [31:0] inp_addr_q, inp_addr_d;
  logic [31:0] weight_addr_q, weight_addr_d;
  logic [31:0] bias_addr_q, bias_addr_d;
  logic [31:0] out_addr_q, out_addr_d;

  logic [INP_BITS-1:0]    inp_flat_q, inp_flat_d;
  logic                   inp_valid_q, inp_valid_d;
  logic [WEIGHT_BITS-1:0] weight_flat_q, weight_flat_d;
  logic                   weight_valid_q, weight_valid_d;
  logic [BIAS_BITS-1:0]   bias_flat_q, bias_flat_d;
  logic                   bias_valid_q, bias_valid_d;
  logic [OUT_BITS-1:0]    out_flat_q, out_flat_d;

  assign inp_o = inp_flat_q;
  assign inp_weight_o = weight_flat_q;
  assign inp_bias_o = bias_flat_q;

  assign inp_valid_o = inp_valid_q;
  assign inp_weight_valid_o = weight_valid_q;
  assign inp_bias_valid_o = bias_valid_q;

  assign output_ready_o = (state_q == IDLE);

  assign m_axi_awsize  = 3'b010;
  assign m_axi_awburst = 2'b01;
  assign m_axi_wstrb   = 4'b1111;
  assign m_axi_bready  = 1'b1;
  assign m_axi_arsize  = 3'b010;
  assign m_axi_arburst = 2'b01;
  assign m_axi_rready  = 1'b1;

  always_comb begin
    state_d = state_q;
    cmd_d = cmd_q;
    addr_d = addr_q;
    beat_d = beat_q;
    inp_addr_d = inp_addr_q;
    weight_addr_d = weight_addr_q;
    bias_addr_d = bias_addr_q;
    out_addr_d = out_addr_q;
    inp_flat_d = inp_flat_q;
    inp_valid_d = inp_valid_q;
    weight_flat_d = weight_flat_q;
    weight_valid_d = weight_valid_q;
    bias_flat_d = bias_flat_q;
    bias_valid_d = bias_valid_q;
    out_flat_d = out_flat_q;

    m_axi_awvalid = 1'b0;
    m_axi_awlen = 8'd0;
    m_axi_awaddr = 32'b0;
    m_axi_wvalid = 1'b0;
    m_axi_wlast = 1'b0;
    m_axi_wdata = 32'b0;
    m_axi_arvalid = 1'b0;
    m_axi_arlen = 8'd0;
    m_axi_araddr = 32'b0;

    if (state_q == IDLE) begin
      if (output_valid_i) begin
        state_d = WRITE_ADDR;
        cmd_d = WRITE_OUT;
        out_flat_d = output_data_i;
        out_addr_d = out_addr_q;
        addr_d = mem_output_base_addr_i + out_addr_q;
        beat_d = 8'd0;
        m_axi_awvalid = 1'b1;
        m_axi_awlen = OUT_WORDS - 1;
        m_axi_awaddr = mem_output_base_addr_i + out_addr_q;
      end else if (!inp_valid_q) begin
        state_d = READ_ADDR;
        cmd_d = READ_INP;
        addr_d = mem_input_base_addr_i + inp_addr_q;
        beat_d = 8'd0;
        m_axi_arvalid = 1'b1;
        m_axi_arlen = INP_WORDS - 1;
        m_axi_araddr = mem_input_base_addr_i + inp_addr_q;
      end else if (!bias_valid_q) begin
        state_d = READ_ADDR;
        cmd_d = READ_BIAS;
        addr_d = mem_bias_base_addr_i + bias_addr_q;
        beat_d = 8'd0;
        m_axi_arvalid = 1'b1;
        m_axi_arlen = BIAS_WORDS - 1;
        m_axi_araddr = mem_bias_base_addr_i + bias_addr_q;
      end else if (!weight_valid_q) begin
        state_d = READ_ADDR;
        cmd_d = READ_WEIGHT;
        addr_d = mem_weight_base_addr_i + weight_addr_q;
        beat_d = 8'd0;
        m_axi_arvalid = 1'b1;
        m_axi_arlen = WEIGHT_WORDS - 1;
        m_axi_araddr = mem_weight_base_addr_i + weight_addr_q;
      end
    end else begin
      case (state_q)
        WRITE_ADDR: begin
          m_axi_awvalid = 1'b1;
          m_axi_awlen = OUT_WORDS - 1;
          m_axi_awaddr = addr_q;
          if (m_axi_awready) begin
            state_d = WRITE_DATA;
            beat_d = 8'd0;
          end
        end
        WRITE_DATA: begin
          m_axi_wvalid = 1'b1;
          m_axi_wlast = (beat_q == OUT_WORDS - 1);
          m_axi_wdata = out_flat_q[beat_q*32 +: 32];
          if (m_axi_wready && m_axi_wvalid) begin
            if (m_axi_wlast) begin
              state_d = WRITE_RESP;
            end else begin
              beat_d = beat_q + 1;
            end
          end
        end
        WRITE_RESP: begin
          if (m_axi_bvalid) begin
            state_d = IDLE;
            out_addr_d = out_addr_q + OUT_BYTES;
          end
        end
        READ_ADDR: begin
          m_axi_arvalid = 1'b1;
          if (cmd_q == READ_INP) m_axi_arlen = INP_WORDS - 1;
          else if (cmd_q == READ_BIAS) m_axi_arlen = BIAS_WORDS - 1;
          else if (cmd_q == READ_WEIGHT) m_axi_arlen = WEIGHT_WORDS - 1;
          m_axi_araddr = addr_q;
          if (m_axi_arready) begin
            state_d = READ_DATA;
            beat_d = 8'd0;
          end
        end
        READ_DATA: begin
          if (m_axi_rvalid && m_axi_rready) begin
            case (cmd_q)
              READ_INP: inp_flat_d[beat_q*32 +: 32] = m_axi_rdata;
              READ_BIAS: bias_flat_d[beat_q*32 +: 32] = m_axi_rdata;
              READ_WEIGHT: weight_flat_d[beat_q*32 +: 32] = m_axi_rdata;
              default: ;
            endcase
            if (m_axi_rlast) begin
              state_d = IDLE;
              if (cmd_q == READ_INP) begin
                inp_valid_d = 1'b1;
                inp_addr_d = inp_addr_q + INP_BYTES;
              end
              if (cmd_q == READ_BIAS) begin
                bias_valid_d = 1'b1;
                bias_addr_d = bias_addr_q + BIAS_BYTES;
              end
              if (cmd_q == READ_WEIGHT) begin
                weight_valid_d = 1'b1;
                weight_addr_d = weight_addr_q + WEIGHT_BYTES;
              end
            end else begin
              beat_d = beat_q + 1;
            end
          end
        end
        default: ;
      endcase
    end

    if (inp_valid_q && inp_ready_i) inp_valid_d = 1'b0;
    if (bias_valid_q && inp_bias_ready_i) bias_valid_d = 1'b0;
    if (weight_valid_q && inp_weight_ready_i) weight_valid_d = 1'b0;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      cmd_q <= NONE;
      addr_q <= 32'b0;
      beat_q <= 8'b0;
      inp_addr_q <= 32'b0;
      weight_addr_q <= 32'b0;
      bias_addr_q <= 32'b0;
      out_addr_q <= 32'b0;
      inp_flat_q <= '0;
      inp_valid_q <= 1'b0;
      weight_flat_q <= '0;
      weight_valid_q <= 1'b0;
      bias_flat_q <= '0;
      bias_valid_q <= 1'b0;
      out_flat_q <= '0;
    end else begin
      state_q <= state_d;
      cmd_q <= cmd_d;
      addr_q <= addr_d;
      beat_q <= beat_d;
      inp_addr_q <= inp_addr_d;
      weight_addr_q <= weight_addr_d;
      bias_addr_q <= bias_addr_d;
      out_addr_q <= out_addr_d;
      inp_flat_q <= inp_flat_d;
      inp_valid_q <= inp_valid_d;
      weight_flat_q <= weight_flat_d;
      weight_valid_q <= weight_valid_d;
      bias_flat_q <= bias_flat_d;
      bias_valid_q <= bias_valid_d;
      out_flat_q <= out_flat_d;
    end
  end

endmodule

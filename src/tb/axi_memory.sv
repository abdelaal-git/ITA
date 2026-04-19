// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

module axi_memory
  import ita_package::*;
#(
  parameter int unsigned MEM_SIZE = 1024*1024, // 1MB
  parameter int unsigned BASE_ADDR = 0
)(
  input  logic         clk_i,
  input  logic         rst_ni,

  // AXI4 slave interface
  input  logic [31:0]  s_axi_awaddr,
  input  logic [7:0]   s_axi_awlen,
  input  logic [2:0]   s_axi_awsize,
  input  logic [1:0]   s_axi_awburst,
  input  logic         s_axi_awvalid,
  output logic         s_axi_awready,
  input  logic [31:0]  s_axi_wdata,
  input  logic [3:0]   s_axi_wstrb,
  input  logic         s_axi_wlast,
  input  logic         s_axi_wvalid,
  output logic         s_axi_wready,
  output logic [1:0]   s_axi_bresp,
  output logic         s_axi_bvalid,
  input  logic         s_axi_bready,

  input  logic [31:0]  s_axi_araddr,
  input  logic [7:0]   s_axi_arlen,
  input  logic [2:0]   s_axi_arsize,
  input  logic [1:0]   s_axi_arburst,
  input  logic         s_axi_arvalid,
  output logic         s_axi_arready,
  output logic [31:0] s_axi_rdata,
  output logic [1:0]   s_axi_rresp,
  output logic         s_axi_rlast,
  output logic         s_axi_rvalid,
  input  logic         s_axi_rready
);

  localparam int unsigned MEM_DEPTH = MEM_SIZE / 4; // 32-bit words

  logic [31:0] mem [0:MEM_DEPTH-1];

  // Write address channel
  logic aw_ready;
  logic [31:0] aw_addr;
  logic [7:0] aw_len;
  logic aw_valid;

  assign s_axi_awready = aw_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      aw_ready <= 1'b1;
      aw_addr <= 32'b0;
      aw_len <= 8'b0;
      aw_valid <= 1'b0;
    end else begin
      if (s_axi_awvalid && aw_ready) begin
        aw_ready <= 1'b0;
        aw_addr <= s_axi_awaddr - BASE_ADDR;
        aw_len <= s_axi_awlen;
        aw_valid <= 1'b1;
      end else if (aw_valid && s_axi_wlast && s_axi_wvalid && s_axi_wready) begin
        aw_ready <= 1'b1;
        aw_valid <= 1'b0;
      end
    end
  end

  // Write data channel
  logic w_ready;
  logic [7:0] w_cnt;

  assign s_axi_wready = w_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      w_ready <= 1'b0;
      w_cnt <= 8'b0;
    end else begin
      if (aw_valid && !w_ready) begin
        w_ready <= 1'b1;
        w_cnt <= 8'b0;
      end else if (w_ready && s_axi_wvalid) begin
        // Write data
        for (int i = 0; i < 4; i++) begin
          if (s_axi_wstrb[i]) begin
            mem[aw_addr[31:2] + w_cnt][i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
          end
        end
        if (s_axi_wlast) begin
          w_ready <= 1'b0;
        end else begin
          w_cnt <= w_cnt + 1;
        end
      end
    end
  end

  // Write response
  logic b_valid;

  assign s_axi_bvalid = b_valid;
  assign s_axi_bresp = 2'b00; // OKAY

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      b_valid <= 1'b0;
    end else begin
      if (s_axi_wlast && s_axi_wvalid && w_ready) begin
        b_valid <= 1'b1;
      end else if (b_valid && s_axi_bready) begin
        b_valid <= 1'b0;
      end
    end
  end

  // Read address channel
  logic ar_ready;
  logic [31:0] ar_addr;
  logic [7:0] ar_len;
  logic ar_valid;

  assign s_axi_arready = ar_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ar_ready <= 1'b1;
      ar_addr <= 32'b0;
      ar_len <= 8'b0;
      ar_valid <= 1'b0;
    end else begin
      if (s_axi_arvalid && ar_ready) begin
        ar_ready <= 1'b0;
        ar_addr <= s_axi_araddr - BASE_ADDR;
        ar_len <= s_axi_arlen;
        ar_valid <= 1'b1;
      end else if (ar_valid && s_axi_rlast && s_axi_rvalid && s_axi_rready) begin
        ar_ready <= 1'b1;
        ar_valid <= 1'b0;
      end
    end
  end

  // Read data channel
  logic r_valid;
  logic r_last;
  logic [7:0] r_cnt;

  assign s_axi_rvalid = r_valid;
  assign s_axi_rlast = r_last;
  assign s_axi_rresp = 2'b00; // OKAY
  assign s_axi_rdata = r_valid ? mem[ar_addr[31:2] + r_cnt] : 32'b0;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      r_valid <= 1'b0;
      r_last <= 1'b0;
      r_cnt <= 8'b0;
    end else begin
      if (ar_valid && !r_valid) begin
        r_valid <= 1'b1;
        r_last <= (ar_len == 0);
        r_cnt <= 8'b0;
      end else if (r_valid && s_axi_rready) begin
        if (r_last) begin
          r_valid <= 1'b0;
        end else begin
          r_cnt <= r_cnt + 1;
          r_last <= (r_cnt == ar_len);
        end
      end
    end
  end

endmodule
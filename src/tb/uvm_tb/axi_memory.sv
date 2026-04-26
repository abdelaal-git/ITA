// Copyright 2024 ITA project.
// SPDX-License-Identifier: SHL-0.51

module axi_memory
  import ita_package::*;
#(
  parameter int unsigned MEM_SIZE = 4*1024*1024, // 1MB
  parameter int unsigned BASE_ADDR = 0
)(
  input  logic         clk_i,
  input  logic         rst_ni,

  // AXI4 slave interface
  input  logic [31:0]  awaddr_i,
  input  logic [7:0]   awlen_i,
  input  logic [2:0]   awsize_i,
  input  logic [1:0]   awburst_i,
  input  logic         awvalid_i,
  output logic         awready_o,
  input  logic [31:0]  wdata_i,
  input  logic [3:0]   wstrb_i,
  input  logic         wlast_i,
  input  logic         wvalid_i,
  output logic         wready_o,
  output logic [1:0]   bresp_o,
  output logic         bvalid_o,
  input  logic         bready_i,

  input  logic [31:0]  araddr_i,
  input  logic [7:0]   arlen_i,
  input  logic [2:0]   arsize_i,
  input  logic [1:0]   arburst_i,
  input  logic         arvalid_i,
  output logic         arready_o,
  output logic [31:0] rdata_o,
  output logic [1:0]   rresp_o,
  output logic         rlast_o,
  output logic         rvalid_o,
  input  logic         rready_i
);

  localparam int unsigned MEM_DEPTH = MEM_SIZE / 4; // 32-bit words

  logic [31:0] mem [0:MEM_DEPTH-1];

  // Write address channel
  logic aw_ready;
  logic [31:0] aw_addr;
  logic [7:0] aw_len;
  logic aw_valid;

  assign awready_o = aw_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      aw_ready <= 1'b1;
      aw_addr <= 32'b0;
      aw_len <= 8'b0;
      aw_valid <= 1'b0;
    end else begin
      if (awvalid_i && aw_ready) begin
        aw_ready <= 1'b0;
        aw_addr <= awaddr_i - BASE_ADDR;
        aw_len <= awlen_i;
        aw_valid <= 1'b1;
      end else if (aw_valid && wlast_i && wvalid_i && wready_o) begin
        aw_ready <= 1'b1;
        aw_valid <= 1'b0;
      end
    end
  end

  // Write data channel
  logic w_ready;
  logic [7:0] w_cnt;

  assign wready_o = w_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      w_ready <= 1'b0;
      w_cnt <= 8'b0;
    end else begin
      if (aw_valid && !w_ready) begin
        w_ready <= 1'b1;
        w_cnt <= 8'b0;
      end else if (w_ready && wvalid_i) begin
        // Write data
        for (int i = 0; i < 4; i++) begin
          if (wstrb_i[i]) begin
            mem[aw_addr[31:2] + w_cnt][i*8 +: 8] <= wdata_i[i*8 +: 8];
          end
        end
        if (wlast_i) begin
          w_ready <= 1'b0;
        end else begin
          w_cnt <= w_cnt + 1;
        end
      end
    end
  end

  // Write response
  logic b_valid;

  assign bvalid_o = b_valid;
  assign bresp_o = 2'b00; // OKAY

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      b_valid <= 1'b0;
    end else begin
      if (wlast_i && wvalid_i && w_ready) begin
        b_valid <= 1'b1;
      end else if (b_valid && bready_i) begin
        b_valid <= 1'b0;
      end
    end
  end

  // Read address channel
  logic ar_ready;
  logic [31:0] ar_addr;
  logic [7:0] ar_len;
  logic ar_valid;

  assign arready_o = ar_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ar_ready <= 1'b1;
      ar_addr <= 32'b0;
      ar_len <= 8'b0;
      ar_valid <= 1'b0;
    end else begin
      if (arvalid_i && ar_ready) begin
        ar_ready <= 1'b0;
        ar_addr <= araddr_i - BASE_ADDR;
        ar_len <= arlen_i;
        ar_valid <= 1'b1;
      end else if (ar_valid && rlast_o && rvalid_o && rready_i) begin
        ar_ready <= 1'b1;
        ar_valid <= 1'b0;
      end
    end
  end

  // Read data channel
  logic r_valid;
  logic r_last;
  logic [7:0] r_cnt;

  assign rvalid_o = r_valid;
  assign rlast_o = r_last;
  assign rresp_o = 2'b00; // OKAY
  assign rdata_o = r_valid ? mem[ar_addr[31:2] + r_cnt] : 32'b0;

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
      end else if (r_valid && rready_i) begin
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

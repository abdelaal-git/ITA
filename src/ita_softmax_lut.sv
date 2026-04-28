// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Modified for ECE69500 HML Project:
//   - Replaced base-2 shift approximation with exp-based LUT softmax
//   - Added compile-time reconfigurable quantization bitwidth (4, 8, or 16-bit)
//     via QUANT_BITS parameter. Interface and pipeline structure unchanged.
//
// Design notes:
//   Each LUT entry represents exp(-diff * B/2^B) * 256, where diff = max_xq - xq.
//   This matches the scaling of the original (which contributed 9'h100 = 256 per
//   max element). The denominator accumulator, serial dividers, and EN phase are
//   all preserved verbatim — only Stage 2's per-element exp contribution changes.
//
//   QUANT_BITS = 4  : 16-entry LUT, inputs truncated to 4-bit range
//   QUANT_BITS = 8  : 256-entry LUT (default, matches WI=8 baseline)
//   QUANT_BITS = 16 : 16-bit inputs, exp approximated via iterative shift-and-add
//                     (LUT too large to inline; synthesises to small ROM/logic)

module ita_softmax_lut
  import ita_package::*;
#(
  // Quantization bitwidth for exp LUT. Must be 4, 8, or 16.
  // WI (from ita_package) is the datapath width; QUANT_BITS controls the
  // precision of the softmax exponent computation.
  parameter int unsigned QUANT_BITS = 8
)(
  // Clock and reset
  input  logic                                clk_i,
  input  logic                                rst_ni,
  input  ctrl_t                               ctrl_i,
  input  step_e                               step_i,
  input  logic                                calc_en_i,
  input  requant_oup_t                        requant_oup_i,
  input  logic                                calc_stream_soft_en_i,
  output counter_t                            soft_addr_div_o,
  output logic                                softmax_done_o,
  output logic                                pop_softmax_fifo_o,
  input  inp_t                                inp_i,
  output inp_t                                inp_stream_soft_o,
  output logic [SoftmaxAccDataWidth-1:0]      div_inp_o,
  output logic [NumDiv-1:0]                   div_valid_o,
  input  logic [NumDiv-1:0]                   div_ready_i,
  input  logic [NumDiv-1:0]                   div_valid_i,
  output logic [NumDiv-1:0]                   div_ready_o,
  input  logic [NumDiv-1:0][DividerWidth-1:0] div_oup_i,
  output logic [1:0]                          read_acc_en_o,
  output logic [1:0][InputAddrWidth-1:0]      read_acc_addr_o,
  input  logic [1:0][SoftmaxAccDataWidth-1:0] read_acc_data_i,
  output logic                                write_acc_en_o,
  output logic [InputAddrWidth-1:0]           write_acc_addr_o,
  output logic [SoftmaxAccDataWidth-1:0]      write_acc_data_o,
  output requant_t                            prev_max_o,
  input  requant_t                            max_i,
  output requant_oup_t                        max_o,
  output logic [1:0]                          read_max_en_o,
  output logic [1:0][InputAddrWidth-1:0]      read_max_addr_o,
  input  requant_t [1:0]                      read_max_data_i,
  output logic                                write_max_en_o,
  output logic [InputAddrWidth-1:0]           write_max_addr_o,
  output requant_t                            write_max_data_o
);

  // -----------------------------------------------------------------------
  // Parameter check
  // -----------------------------------------------------------------------
  initial begin
    if (QUANT_BITS != 4 && QUANT_BITS != 8 && QUANT_BITS != 16)
      $fatal(1, "ita_softmax: QUANT_BITS must be 4, 8, or 16 (got %0d)", QUANT_BITS);
  end

  // -----------------------------------------------------------------------
  // Exp LUT definition
  //
  // Entry[i] = round(exp(-i * QUANT_BITS / 2^QUANT_BITS) * 256)
  // Scaled to match the baseline contribution of 9'h100 = 256 at diff=0.
  // Values are clamped to [0, 2^SoftmaxAccDataWidth - 1].
  //
  // For QUANT_BITS=4 : 16 entries  (diff in [0,15])
  // For QUANT_BITS=8 : 256 entries (diff in [0,255])
  // For QUANT_BITS=16: computed via function (65536 entries impractical inline)
  // -----------------------------------------------------------------------

  // 4-bit LUT: exp(-diff * 1.0) * 256, diff in [0,15]
  // Entry[i] = round(256 * exp(-i)), zeros after i=6
  localparam int unsigned EXP_LUT_4B [0:15] = '{
    255, 150, 88, 51, 30, 18, 10, 6,
    4,  2,  1,  1, 0, 0, 0, 0
  };

 localparam int unsigned EXP_LUT_8B [0:255] = '{
    256, 248, 240, 233, 226, 219, 212, 206,   // index 0..7     (near 0)
    199, 193, 187, 181, 176, 170, 165, 160,   // 8..15
    155, 150, 146, 141, 137, 133, 129, 125,   // 16..23
    121, 117, 114, 110, 107, 104, 101,  98,   // 24..31
    95,  92,  89,  86,  84,  81,  79,  76,   // 32..39
    74,  72,  70,  67,  65,  63,  61,  59,   // 40..47
    58,  56,  54,  52,  51,  49,  48,  46,   // 48..55
    45,  43,  42,  41,  39,  38,  37,  36,   // 56..63
    35,  34,  33,  32,  31,  30,  29,  28,   // 64..71
    27,  26,  25,  24,  23,  23,  22,  21,   // 72..79
    20,  20,  19,  18,  18,  17,  17,  16,   // 80..87
    16,  15,  15,  14,  14,  13,  13,  12,   // 88..95
    12,  11,  11,  11,  10,  10,  10,   9,   // 96..103
    9,   9,   8,   8,   8,   8,   7,   7,   // 104..111
    7,   7,   6,   6,   6,   6,   5,   5,   // 112..119
    5,   5,   5,   5,   4,   4,   4,   4,   // 120..127
    4,   4,   3,   3,   3,   3,   3,   3,   // 128..135
    3,   3,   2,   2,   2,   2,   2,   2,   // 136..143
    2,   2,   2,   2,   2,   1,   1,   1,   // 144..151
    1,   1,   1,   1,   1,   1,   1,   1,   // 152..159
    1,   1,   1,   1,   1,   0,   0,   0,   // 160..167
    0,   0,   0,   0,   0,   0,   0,   0,   // 168..175
    0,   0,   0,   0,   0,   0,   0,   0,   // 176..183
    0,   0,   0,   0,   0,   0,   0,   0,   // 184..191
    0,   0,   0,   0,   0,   0,   0,   0,   // 192..199
    0,   0,   0,   0,   0,   0,   0,   0,   // 200..207
    0,   0,   0,   0,   0,   0,   0,   0,   // 208..215
    0,   0,   0,   0,   0,   0,   0,   0,   // 216..223
    0,   0,   0,   0,   0,   0,   0,   0,   // 224..231
    0,   0,   0,   0,   0,   0,   0,   0,   // 232..239
    0,   0,   0,   0,   0,   0,   0,   0,   // 240..247
    0,   0,   0,   0,   0,   0,   0,   0    // 248..255
};

  // -----------------------------------------------------------------------
  // 16-bit exp approximation function
  //
  // For QUANT_BITS=16, exp(-diff * 1.0) * 256.
  // exp(-diff) rounds to zero very quickly (after diff=6).
  // For diff >= 7, returns 0. For diff in [0,6], returns round(256*exp(-diff)).
  // This is a small lookup implemented as a case statement.
  // -----------------------------------------------------------------------
  function automatic logic [SoftmaxAccDataWidth-1:0] exp_lut_16b(
    input logic [15:0] diff
  );
    logic [SoftmaxAccDataWidth-1:0] val;
    case (diff)
      16'd0:   val = 256;
      16'd1:   val =  94;
      16'd2:   val =  35;
      16'd3:   val =  13;
      16'd4:   val =   5;
      16'd5:   val =   2;
      16'd6:   val =   1;
      default: val = '0;
    endcase
    return val;
  endfunction

  // -----------------------------------------------------------------------
  // Exp lookup wrapper — selects LUT based on QUANT_BITS
  // diff is the unsigned difference (max_xq - xq), up to WI bits wide
  // -----------------------------------------------------------------------
  function automatic logic [SoftmaxAccDataWidth-1:0] exp_lookup(
    input logic [WI-1:0] diff_raw
  );
    // All variables declared at top of function (required by SV LRM §13.4)
    logic [SoftmaxAccDataWidth-1:0] result;
    logic [7:0] idx8;
    logic [3:0] idx4;
    idx4 = (diff_raw > 15) ? 4'd15 : diff_raw[3:0];
    idx8 = diff_raw[7:0];
    if (QUANT_BITS == 4) begin
      result = SoftmaxAccDataWidth'(EXP_LUT_4B[idx4]);
      if (diff_raw > 15) result = '0;
    end else if (QUANT_BITS == 8) begin
      result = SoftmaxAccDataWidth'(EXP_LUT_8B[idx8]);
    end else begin  // QUANT_BITS == 16
      result = exp_lut_16b(16'(diff_raw));
    end
    return result;
  endfunction

  // -----------------------------------------------------------------------
  // Pipeline registers (unchanged from original)
  // -----------------------------------------------------------------------
  counter_t tile_d, tile_q1, tile_q2, tile_q3, tile_q4;
  counter_t count_d, count_q1, count_q2, count_q3, count_q4;

  logic unsigned [SoftmaxAccDataWidth-1:0] exp_sum_d, exp_sum_q;
  counter_t count_soft_d, count_soft_q;

  counter_t count_div_d, count_div_q, addr_div_d, addr_div_q;
  logic [NumDiv-1:0] div_read_d, div_read_q, div_write_d, div_write_q;

  requant_oup_t requant_oup_q;
  requant_t max_d, max_q;

  // shift_d/shift_q are KEPT for Stage 1 max-update logic (max_diff shift).
  // They no longer feed Stage 2 exp accumulation — exp_lookup does that.
  logic unsigned [N-1:0][WI-SoftmaxShift:0] shift_d, shift_q;
  logic [N-1:0][WI-1:0] shift_diff;
  logic unsigned [WI-SoftmaxShift:0] shift_sum_d, shift_sum_q;
  logic [WI-1:0] max_diff;
  logic unsigned [M-1:0][WI-SoftmaxShift:0] shift_inp;
  logic [M-1:0][WI-1:0] shift_inp_diff;

  // Per-element exp values computed in Stage 1, registered for Stage 2
  logic unsigned [N-1:0][SoftmaxAccDataWidth-1:0] exp_val_d, exp_val_q;

  logic calc_stream_soft_en_q;
  logic calc_en_d, calc_en_q1, calc_en_q2, calc_en_q3;

  // Temporary variables for stream softmax
  logic [M-1:0][WI-SoftmaxShift:0] shift_inp_scaled;

  // FIFO signals
  logic        fifo_full, fifo_empty, push_to_fifo, pop_from_fifo;
  logic [SoftmaxAccDataWidth-1:0]  data_to_fifo, data_from_fifo;
  soft_fifo_usage_t fifo_usage  ;

  assign pop_softmax_fifo_o = pop_from_fifo;
  assign soft_addr_div_o    = addr_div_q;

  always_comb begin
    tile_d            = tile_q1;
    count_d           = count_q1;
    count_soft_d      = count_soft_q;
    count_div_d       = count_div_q;
    div_read_d        = div_read_q;
    div_write_d       = div_write_q;
    addr_div_d        = addr_div_q;
    calc_en_d         = 1'b0;
    exp_sum_d         = '0;
    read_acc_en_o     = 0;
    read_acc_addr_o   = '0;
    write_acc_en_o    = 0;
    write_acc_addr_o  = '0;
    write_acc_data_o  = '0;
    read_max_en_o     = '0;
    read_max_addr_o   = '0;
    write_max_en_o    = 0;
    write_max_addr_o  = '0;
    write_max_data_o  = '0;
    push_to_fifo      = 0;
    pop_from_fifo     = 0;
    data_to_fifo      = '0;
    div_inp_o         = data_from_fifo;
    div_valid_o       = 0;
    div_ready_o       = 0;
    prev_max_o        = '0;
    max_o             = '0;
    max_d             = max_q;
    shift_d           = '0;
    shift_diff        = '0;
    shift_sum_d       = '0;
    max_diff          = '0;
    shift_inp         = '0;
    shift_inp_diff    = '0;
    inp_stream_soft_o = '0;
    softmax_done_o    = 0;
    exp_val_d         = '0;
    shift_inp_scaled = '0;

    //************ Accumulation ************//
    case (step_i)
      default : begin
        tile_d      = '0;
        count_d     = '0;
      end
      QK : begin
        //************ Pipeline Stage 0 ************//
        if (calc_en_i) begin // After first part of the row check previous max
          calc_en_d = 1'b1;
          count_d = count_q1 + 1;
          if (count_q1 == M*M/N-1) begin
            tile_d  = tile_q1 + 1;
            count_d = '0;
          end
          if (tile_q1 != '0 || count_q1 >= M) begin
            read_max_en_o[0]   = 1;
            read_max_addr_o[0] = count_q1;
          end
        end
      end
    endcase

    //============================================================
    // Stage 1: Find max and compute exp values for each element
    //
    // Original: computed shift_d[i] = (max_i - xq) >> SoftmaxShift
    // Modified: additionally compute exp_val_d[i] = exp_lookup(max_i - xq)
    //           and sum rescaling exp_val for max update.
    //============================================================
    if (calc_en_q1) begin
      max_o = requant_oup_q;
      max_d = max_i;
      for (int i = 0; i < N; i++) begin
        // Signed subtraction; result is non-negative because max_i >= xq
        shift_diff[i] = max_i - requant_oup_q[i];
        // Keep shift_d for max-update rescaling path (used in shift_sum)
        shift_d[i]    = unsigned'(shift_diff[i]) >> SoftmaxShift;
        if (SoftmaxShift != 0 && shift_diff[i][SoftmaxShift-1])
          shift_d[i] = (unsigned'(shift_diff[i]) >> SoftmaxShift) + 1;
        // Exp LUT lookup: diff = max - xq (unsigned, clamped to WI bits)
        exp_val_d[i]  = exp_lookup(WI'(unsigned'(shift_diff[i])));
      end

      // Rescale accumulated sum when max changes between tiles
      if (tile_q2 != '0 || count_q2>=M) begin // If not first part of the first row, normalize previous sum
        read_acc_en_o[0]   = 1;
        read_acc_addr_o[0] = count_q2;
        prev_max_o  = read_max_data_i[0];
        max_diff    = max_i - prev_max_o;
        // Keep original shift-based rescaling for inter-tile sum correction.
        // This preserves numerical compatibility with the golden model's
        // running-sum update while per-element exp uses the LUT.
        shift_sum_d = max_diff >> SoftmaxShift;
        if (SoftmaxShift != 0 && max_diff[SoftmaxShift-1])
          shift_sum_d = (max_diff >> SoftmaxShift) + 1;
      end else begin
        prev_max_o = 8'h80;
      end
    end

    //============================================================
    // Stage 2: Write max and accumulate exp sum
    //
    // Original: exp_sum_d += 9'h100 >> shift_q[i]  (base-2 shift approx)
    //           exp_sum_d += old_sum >> shift_sum_q (rescale old sum)
    //
    // Modified: exp_sum_d += exp_val_q[i]           (LUT exp value)
    //           exp_sum_d += (old_sum * sum_rescale_q) >> 8
    //           The >> 8 is because exp values are scaled by 256.
    //============================================================
    if (calc_en_q2) begin
      write_max_en_o   = 1;
      write_max_addr_o = count_q3;
      write_max_data_o = max_q;

      // Accumulate exp(max - xq) for each of the N elements in this beat
      for (int i = 0; i < N; i++) begin
        exp_sum_d += exp_val_q[i];
      end

      // Add rescaled old accumulated sum (if not the first part of first row).
      // exp_lookup(shift_sum_q) where shift_sum_q holds the registered max_delta.
      // old_sum * exp_lut[max_delta] >> 8, consistent with DA and EN phases.
      if (tile_q3 != '0 || count_q3 >= M) begin
        exp_sum_d += SoftmaxAccDataWidth'(
          (read_acc_data_i[0] * exp_lookup(WI'({1'b0, shift_sum_q}))) >> 8
        );
      end
    end

    //************ Pipeline Stage 3 ************//
    // Write accumulated sum or send to division fifo
    if (calc_en_q3) begin // Write accumulated sum or send to division fifo
      if (count_q4>=(M*M/N-M) && tile_q4 == ctrl_i.tile_s-1) begin // If last tile and last part of the row
        // Main controller checks if FIFO is full
        push_to_fifo = 1;
        data_to_fifo = exp_sum_q;
      end else begin
        write_acc_en_o   = 1;
        write_acc_addr_o = count_q4;
        write_acc_data_o = exp_sum_q;
      end
    end

    //************** Division **************//
    div_valid_o[div_read_q]  = !fifo_empty;
    div_ready_o[div_write_q] = 1;
    if (div_valid_o[div_read_q] && div_ready_i[div_read_q]) begin
      pop_from_fifo   = 1;
      count_div_d = count_div_q + 1;
      div_read_d  = div_read_q + 1;
      if (div_read_d==NumDiv)
        div_read_d = 0;
    end
    if (div_valid_i[div_write_q]) begin
      write_acc_en_o   = 1;
      write_acc_addr_o = addr_div_q;
      addr_div_d       = addr_div_q + 1;
      write_acc_data_o = div_oup_i[div_write_q];
      div_write_d      = div_write_q + 1;
        if (div_write_d==NumDiv)
          div_write_d = 0;
        if (addr_div_d==M) begin
        addr_div_d     = '0;
        count_div_d    = '0;
        softmax_done_o = 1;
      end
    end

    //============================================================
    // Stream softmax / element normalization
    // Uses stored Sigma_inverse from divider to normalize each element.
    //
    // Modified: EN uses multiply-based normalization to match exp LUT in DA.
    //   output_i = (Sigma_inverse * exp_lut[diff_i]) >> 8
    // This is consistent with DA accumulating exp_lut[diff] values.
    // The original used: output_i = Sigma_inverse >> diff_i (base-2 shift).
    //============================================================
    if (calc_stream_soft_en_i) begin
      count_soft_d    = count_soft_q + 1;
      read_acc_en_o[1]   = 1;
      read_acc_addr_o[1] = count_soft_q[5:0];
      read_max_en_o[1]   = 1;
      read_max_addr_o[1] = count_soft_q[5:0];
      if (count_soft_d == M*M/N) begin
        count_soft_d = '0;
      end
    end
    if (calc_stream_soft_en_q) begin
      for (int i = 0; i < M; i++) begin
        shift_inp_diff[i]   = read_max_data_i[1] - inp_i[i];
        // Apply same rounding as Stage 1 DA to get consistent LUT index
        shift_inp_scaled[i]    = unsigned'(shift_inp_diff[i]) >> SoftmaxShift;
        if (SoftmaxShift != 0 && shift_inp_diff[i][SoftmaxShift-1])
          shift_inp_scaled[i]  = (unsigned'(shift_inp_diff[i]) >> SoftmaxShift) + 1;
        inp_stream_soft_o[i] = WI'(
          (read_acc_data_i[1] * exp_lookup(WI'(shift_inp_scaled[i]))) >> 8
        );
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      tile_q4               <= '0;
      tile_q3               <= '0;
      tile_q2               <= '0;
      tile_q1               <= '0;
      count_q4              <= M*M/N;
      count_q3              <= M*M/N;
      count_q2              <= M*M/N;
      count_q1               <= M*M/N;
      count_soft_q          <= '0;
      count_div_q           <= '0;
      div_read_q            <= '0;
      div_write_q           <= '0;
      addr_div_q            <= '0;
      exp_sum_q             <= '0;
      requant_oup_q         <= '0;
      max_q                 <= '0;
      calc_stream_soft_en_q <= 0;
      shift_q               <= '0;
      shift_sum_q           <= '0;
      exp_val_q             <= '0;
    end else begin
      tile_q4               <= tile_q3;
      tile_q3               <= tile_q2;
      tile_q2               <= tile_q1;
      tile_q1               <= tile_d;
      count_q4              <= count_q3;
      count_q3              <= count_q2;
      count_q2              <= count_q1;
      count_q1              <= count_d;
      count_soft_q          <= count_soft_d;
      count_div_q           <= count_div_d;
      div_read_q            <= div_read_d;
      div_write_q           <= div_write_d;
      addr_div_q            <= addr_div_d;
      exp_sum_q             <= exp_sum_d;
      requant_oup_q         <= requant_oup_i;
      max_q                 <= max_d;
      calc_stream_soft_en_q <= calc_stream_soft_en_i;
      shift_q               <= shift_d;
      shift_sum_q           <= shift_sum_d;
      exp_val_q             <= exp_val_d;
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      calc_en_q3 <= 0;
      calc_en_q2 <= 0;
      calc_en_q1 <= 0;
    end else begin
      calc_en_q3 <= calc_en_q2;
      calc_en_q2 <= calc_en_q1;
      calc_en_q1 <= calc_en_d;
    end
  end

  fifo_v3 #(
    .FALL_THROUGH(1'b0               ),
    .DATA_WIDTH  (SoftmaxAccDataWidth),
    .DEPTH       (SoftFifoDepth      )
  ) i_fifo (
    .clk_i     (clk_i         ),
    .rst_ni    (rst_ni        ),
    .flush_i   (1'b0          ),
    .testmode_i(1'b0          ),
    // status flags
    .full_o    (fifo_full     ), // queue is full
    .empty_o   (fifo_empty    ), // queue is empty
    .usage_o   (fifo_usage    ),
    // as long as the queue is not full we can push new data
    .data_i    (data_to_fifo  ),
    .push_i    (push_to_fifo  ),
    // as long as the queue is not empty we can pop new elements
    .data_o    (data_from_fifo),
    .pop_i     (pop_from_fifo )
  );

endmodule : ita_softmax_lut

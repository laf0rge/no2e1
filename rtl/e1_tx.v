/*
 * e1_tx.v
 *
 * vim: ts=4 sw=4
 *
 * E1 TX top-level
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-W-2.0
 */

`default_nettype none

module e1_tx #(
	parameter integer LIU = 0,
	parameter integer MFW = 7
)(
	// IO pads
		// Raw PHY
	output wire pad_tx_hi,
	output wire pad_tx_lo,

		// LIU
	output wire pad_tx_data,
	output wire pad_tx_clk,

	// Buffer interface
	input  wire [7:0] buf_data,
	output wire [4:0] buf_ts,
	output wire [3:0] buf_frame,
	output wire [MFW-1:0] buf_mf,
	output wire buf_re,
	input  wire buf_rdy,

	// BD interface
	input  wire [MFW-1:0] bd_mf,
	input  wire [1:0] bd_crc_e,
	input  wire bd_valid,
	output reg  bd_done,
	output reg  bd_miss,

	// Loopback input
	input  wire lb_bit,
	input  wire lb_valid,

	// Control
	input  wire ctrl_time_src,  // 0=internal, 1=external
	input  wire ctrl_do_framing,
	input  wire ctrl_do_crc4,
	input  wire ctrl_loopback,
	input  wire alarm,

	// Timing sources
	input  wire ext_tick,
	output wire int_tick,

	// Common
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	// Buffer Descriptor handling
	reg  mf_valid;

	// Framer
	wire [7:0] f_data;
	wire [1:0] f_crc_e;
	wire [3:0] f_frame;
	wire [4:0] f_ts;
	wire f_mf_first;
	wire f_mf_last;
	wire f_req;
	wire f_rdy;

	// Low-level (bit -> pulses)
	wire ll_bit, ll_valid;
	wire ll_pg_hi,  ll_pg_lo, ll_pg_stb;
	wire ll_raw_hi, ll_raw_lo;

	// Pulse generator
	reg  [4:0] pg_hi;
	reg  [4:0] pg_lo;


	// Frame generation
	// ----------------

	// Buffer Descriptor
		// Keep track if we're in a valid MF at all
	always @(posedge clk or posedge rst)
		if (rst)
			mf_valid <= 1'b0;
		else if (f_req & f_mf_first)
			mf_valid <= bd_valid;

		// We register those because a 1 cycle delay doesn't matter
	always @(posedge clk)
	begin
		bd_done <= f_req & f_mf_last  &  mf_valid;
		bd_miss <= f_req & f_mf_first & ~bd_valid;
	end

	// Buffer read
	assign buf_ts    = f_ts;
	assign buf_frame = f_frame;
	assign buf_mf    = bd_mf;
	assign buf_re    = f_req & bd_valid;

	assign f_data  = buf_data;
	assign f_crc_e = bd_crc_e;
	assign f_rdy   = buf_rdy & mf_valid;

	// Framer
	e1_tx_framer framer_I (
		.in_data(f_data),
		.in_crc_e(f_crc_e),
		.in_frame(f_frame),
		.in_ts(f_ts),
		.in_mf_first(f_mf_first),
		.in_mf_last(f_mf_last),
		.in_req(f_req),
		.in_rdy(f_rdy),
		.out_bit(ll_bit),
		.out_valid(ll_valid),
		.lb_bit(lb_bit),
		.lb_valid(lb_valid),
		.ctrl_time_src(ctrl_time_src),
		.ctrl_do_framing(ctrl_do_framing),
		.ctrl_do_crc4(ctrl_do_crc4),
		.ctrl_loopback(ctrl_loopback),
		.alarm(alarm),
		.ext_tick(ext_tick),
		.int_tick(int_tick),
		.clk(clk),
		.rst(rst)
	);


	// Low-level
	// ---------

	generate
		if (LIU == 0) begin

			// HDB3 encoding
			hdb3_enc hdb3_I (
				.out_pos(ll_pg_hi),
				.out_neg(ll_pg_lo),
				.out_valid(ll_pg_stb),
				.in_data(ll_bit),
				.in_valid(ll_valid),
				.clk(clk),
				.rst(rst)
			);

			// Pulse generation
			always @(posedge clk)
			begin
				if (rst) begin
					pg_hi <= 0;
					pg_lo <= 0;
				end else begin
					if (ll_pg_stb) begin
						pg_hi <= ll_pg_hi ? 5'h19 : 5'h00;
						pg_lo <= ll_pg_lo ? 5'h19 : 5'h00;
					end else begin
						pg_hi <= pg_hi - pg_hi[4];
						pg_lo <= pg_lo - pg_lo[4];
					end
				end
			end

			assign ll_raw_hi = pg_hi[4];
			assign ll_raw_lo = pg_lo[4];

			// PHY
			e1_tx_phy phy_I (
				.pad_tx_hi(pad_tx_hi),
				.pad_tx_lo(pad_tx_lo),
				.tx_hi(ll_raw_hi),
				.tx_lo(ll_raw_lo),
				.clk(clk),
				.rst(rst)
			);

		end else begin

			// LIU interface
			e1_tx_liu liuif_I (
				.pad_tx_data(pad_tx_data),
				.pad_tx_clk(pad_tx_clk),
				.in_data(ll_bit),
				.in_valid(ll_valid),
				.clk(clk),
				.rst(rst)
			);

		end
	endgenerate

endmodule // e1_tx

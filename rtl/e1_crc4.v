/*
 * e1_crc4.v
 *
 * vim: ts=4 sw=4
 *
 * E1 CRC4 computation
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-W-2.0
 */

`default_nettype none

module e1_crc4 #(
	parameter INIT = 4'h0,
	parameter POLY = 4'h3
)(
	// Input
	input  wire in_bit,
	input  wire in_first,
	input  wire in_valid,

	// Output (updated 1 cycle after input)
	output wire [3:0] out_crc4,

	// Common
	input  wire clk,
	input  wire rst
);

	reg  [3:0] state;
	wire [3:0] state_fb_mux;
	wire [3:0] state_upd_mux;

	assign state_fb_mux  = (INIT & {4{in_first}}) | (state & {4{~in_first}}); // in_first ? INIT : state
	assign state_upd_mux = (state_fb_mux[3] != in_bit) ? POLY : 0;

	always @(posedge clk)
		if (in_valid)
			state <= { state_fb_mux[2:0], 1'b0 } ^ state_upd_mux;

	assign out_crc4 = state;

endmodule // e1_crc4

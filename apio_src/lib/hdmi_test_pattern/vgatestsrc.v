////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	vgatestsrc.v
//
// Project:	Customized from vgasim (original by Dan Gisselquist)
//
// Purpose:	Pixel position tracker and passthrough module.
//		Calculates current X/Y position in the active display area
//		and provides it as outputs (o_xpos, o_ypos) for addressing
//		an external ROM or other pixel source. Receives external
//		pixel data on i_pixel and passes it through to o_pixel
//		(with one-cycle pipeline, matching original behavior).
//
//		All original test pattern generation (color bars, gradients,
//		borders, etc.) has been completely removed.
//
//   	Modified for ROM integration
//
////////////////////////////////////////////////////////////////////////////////
//
`default_nettype none
//
module	vgatestsrc(i_pixclk, i_reset,
		// External connections
		i_width, i_height,
		i_rd, i_newline, i_newframe,
		// Outputs
		o_pixel,
		o_xpos, o_ypos,
		// Input from external source (e.g., ROM)
		i_pixel);

	parameter	BITS_PER_COLOR = 4,
			    HW=12, VW=12;
	localparam	BPC = BITS_PER_COLOR,
			    BITS_PER_PIXEL = 3 * BPC,
			    BPP = BITS_PER_PIXEL;
	//
	input	wire            i_pixclk, i_reset;
	input	wire [HW-1:0]	i_width, i_height;
	input	wire            i_rd, i_newline, i_newframe;
	output	reg	 [BPP-1:0]	o_pixel;
	output	wire [HW-1:0]	o_xpos;
	output	wire [VW-1:0]	o_ypos;
	input	wire [BPP-1:0]	i_pixel;

	reg	[HW-1:0]	xpos;
	reg	[VW-1:0]	ypos;

	assign	o_xpos = xpos;
	assign	o_ypos = ypos;

	// Horizontal position within active line (0 to i_width-1)
	always @(posedge i_pixclk)
	if (i_reset)
		xpos <= 0;
	else if (i_rd)
		xpos <= (xpos == i_width-1) ? 0 : xpos + 1;

	// Vertical position (row/line within frame, 0 to i_height-1)
	always @(posedge i_pixclk)
	if (i_reset)
		ypos <= 0;
	else if (i_newframe)
		ypos <= 0;
	else if (i_newline)
		ypos <= ypos + 1;

	// Passthrough external pixel data during active area
	// (registered - matches original one-cycle pipeline behavior)
	// Outside active area we drive black (safe default, though unused)
	always @(posedge i_pixclk)
	begin
		//if (i_rd)
			o_pixel <= i_pixel;
		//else
		//	o_pixel <= {BPP{1'b0}};	// black
	end

endmodule

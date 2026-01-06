`default_nettype none

module hdmi_ctler (
    input clk_25mhz,
    input clk_250mhz,
    output [3:0] gpdi_dp, gpdi_dn,
    output [11:0] xpos,
    output [11:0] ypos,
    input [23:0] color
);

wire [7:0] red, grn, blu;
wire [23:0] pixel;
assign red= pixel[23:16];
assign grn= pixel[15:8];
assign blu= pixel[7:0];

wire o_red;
wire o_grn;
wire o_blu;
wire o_rd, o_newline, o_newframe;

// A reset line that goes low after 16 ticks
reg [2:0] reset_cnt = 0;
wire reset = ~reset_cnt[2];
always @(posedge clk_25mhz)
    if (reset) reset_cnt <= reset_cnt + 1;


llhdmi llhdmi_instance(
    .i_tmdsclk(clk_250mhz), .i_pixclk(clk_25mhz),
    .i_reset(reset), .i_red(red), .i_grn(grn), .i_blu(blu),
    .o_rd(o_rd), .o_newline(o_newline), .o_newframe(o_newframe),
    .o_red(o_red), .o_grn(o_grn), .o_blu(o_blu)
);

vgatestsrc #(.BITS_PER_COLOR(8))
    vgatestsrc1 (
        .i_pixclk(clk_25mhz),
        .i_reset(reset),
        .i_width(12'd640),
        .i_height(12'd480),
        .i_rd(o_rd),
        .i_newline(o_newline),
        .i_newframe(o_newframe),
        .o_pixel(pixel),
        .o_xpos(xpos),
        .o_ypos(ypos),
        .i_pixel(color)
    );


OBUFDS OBUFDS_red(.I(o_red), .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
OBUFDS OBUFDS_grn(.I(o_grn), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
OBUFDS OBUFDS_blu(.I(o_blu), .O(gpdi_dp[0]), .OB(gpdi_dn[0]));
OBUFDS OBUFDS_clock(.I(clk_25mhz), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));

endmodule

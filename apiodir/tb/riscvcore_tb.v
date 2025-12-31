`timescale 1ns / 1ns
module riscvcore_tb();

reg clk;
initial clk = 0;
always #20 clk = ~clk;

//debug io
wire [7:0] GPIO;
//led io
wire [2:0] LED;
//sdram io
wire SDRAM_CLK;
wire SDRAM_CKE;
wire SDRAM_RAS_N;
wire SDRAM_CAS_N;
wire SDRAM_WE_N;
wire SDRAM_CS_N;
wire [12:0] SDRAM_A;
wire [1:0] SDRAM_BA;
wire [15:0] SDRAM_DQ;
wire SDRAM_DQML;
wire SDRAM_DQMH;
//hdmi io
wire [3:0] gpdi_dp, gpdi_dn;
genvar i;
generate
    for ( i = 0; i < 16; i = i + 1) begin : pulluploop
        pullup(SDRAM_DQ[i]);
    end
endgenerate

riscvcore core1(
.clk(clk),
//gpio io
.GPIO(GPIO),
//led io
.LED(LED),
//sdram io
.SDRAM_CLK(SDRAM_CLK),
.SDRAM_CKE(SDRAM_CKE),
.SDRAM_RAS_N(SDRAM_RAS_N),
.SDRAM_CAS_N(SDRAM_CAS_N),
.SDRAM_WE_N(SDRAM_WE_N),
.SDRAM_CS_N(SDRAM_CS_N),
.SDRAM_A(SDRAM_A),
.SDRAM_BA(SDRAM_BA),
.SDRAM_DQ(SDRAM_DQ),
.SDRAM_DQML(SDRAM_DQML),
.SDRAM_DQMH(SDRAM_DQMH),
//hdmi io
.gpdi_dp(gpdi_dp),
.gpdi_dn(gpdi_dn)
);
initial begin
    $dumpvars(0, riscvcore_tb);
    //#400000
	@(posedge core1.initFinish);
    //@(posedge (core1.pc == 32'h20));
    //@(posedge (core1.fb_ypos == 12'd479));
    #400000;
	$finish;
end

endmodule

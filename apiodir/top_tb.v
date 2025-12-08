`timescale 1ns / 1ns
module top_tb();

reg clk;
initial clk = 0;
always #20 clk = ~clk;

reg rst_n;
wire [7:0] debug;

top t1(
.clk(clk),
.rst_n(rst_n),
.stall(1'b0),
.debug(debug)
);

initial begin
	$dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
	//$readmemh("inst.rom", t1.im.rom);
	rst_n = 0;
	#80
	rst_n = 1'b1;
	#2000
	$finish;
	end

endmodule

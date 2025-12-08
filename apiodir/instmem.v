module instMem(
input clk,
input [7:0] addr,
output [31:0] dataOut
);

reg [31:0] rom [255:0];

initial begin
	$readmemh("inst.rom", rom, 0, 6);
end

assign dataOut = rom[addr[7:2]];

endmodule

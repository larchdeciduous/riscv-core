`default_nettype none
module instMem(
input clk,
input [11:0] addr,
output reg [31:0] dataOut
);

reg [31:0] rom [1023:0];

initial begin
	$readmemh("inst.rom", rom, 0, 1023);
end

always @(posedge clk) begin
    dataOut <= rom[addr[11:2]];
end

endmodule

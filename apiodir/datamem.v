module datamem(
input clk,
input [31:0] data,
input [7:0] addr,
input memRead,
input memWrite,
output ready,
output waitting,
output [31:0] dataOut 
);


reg [31:0] mem [256:0];

integer i;
always @(posedge clk) begin
	if(memWrite)
		mem[addr] <= data;
end
assign dataOut = mem[addr];

endmodule

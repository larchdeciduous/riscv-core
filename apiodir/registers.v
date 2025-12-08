module registers(
input clk,
input rst,
input rdWrite,
input [4:0] rs1Addr,
input [4:0] rs2Addr,
input [4:0] rdAddr,
input [31:0] rdData,
output [31:0] rs1Data,
output [31:0] rs2Data
);

reg [31:0] registers [31:0];

assign rs1Data = (rs1Addr) ? registers[rs1Addr] : 32'b0;
assign rs2Data = (rs2Addr) ? registers[rs2Addr] : 32'b0;


//integer i;
always @(posedge clk) begin
	/*
	if(rst) begin
		for (i = 0; i < 32; i = i + 1) begin
			registers[i] = 0;
		end
	end
	*/
	if(rdWrite) 
		registers[rdAddr] <= rdData;
end

endmodule

module riscvcore(
input clk
);
wire [31:0] pc, instruction, aluOut, aluSrc1, aluSrc2, aluIn1, aluIn2, rs1Data, rs2Data, memOut;
reg [31:0] rdData;//wire
wire [4:0] rs1Addr, rs2Addr, rdAddr;
wire [3:0] aluCtl;
wire [1:0] rdSrc;
wire aluSrc1En, aluSrc2En, rdWrite, memWrite, memRead, ifZero, stall, allReady, memReady;
//wire [7:0] debug_n;



assign allReady = memReady;
//assign stall = 1'b1;
//assign stall = (pc >= 31'h9);
//assign debug = {rdWrite, ~debug_n[6:0]};
assign debug = 0;


always @(*) begin
	case(rdSrc)
		2'b00: rdData = aluOut;
		2'b01: rdData = memOut;
		2'b10: rdData = pc + 4'h4;
		2'b11: rdData = aluOut;
	endcase
end

assign aluIn1 = (aluSrc1En) ? aluSrc1 : rs1Data;
assign aluIn2 = (aluSrc2En) ? aluSrc2 : rs2Data;

instMem im(
.clk(clk),
.addr(pc[7:0]),
.dataOut(instruction)
);

insf insFetch(
.clk(clk),
.rst(~allReady),
.stall(stall),
.instruction(instruction),
.pc(pc),
.rs1(rs1Addr),
.rs2(rs2Addr),
.rs1Data(rs1Data),
.rs2Data(rs2Data),
.rd(rdAddr),
.aluCtl(aluCtl),
.aluSrc1(aluSrc1),
.aluSrc1En(aluSrc1En),
.aluSrc2(aluSrc2),
.aluSrc2En(aluSrc2En),
.rdSrc(rdSrc),
.rdWrite(rdWrite),
.memWrite(memWrite),
.memRead(memRead)
);

registers rf(
.clk(clk),
.rst(~allReady),
.rdWrite(rdWrite),
.rs1Addr(rs1Addr),
.rs2Addr(rs2Addr),
.rdAddr(rdAddr),
.rdData(rdData),
.rs1Data(rs1Data),
.rs2Data(rs2Data)
);

alu aluu(
.clk(clk),
.ctl(aluCtl),
.src1(aluIn1),
.src2(aluIn2),
.result(aluOut),
.ifZero(ifZero)
);

datamem dm(
.clk(clk),
.data(rs2Data),
.addr(aluOut[7:0]),
.memRead(memRead),
.memWrite(memWrite),
.ready(memReady),
.dataOut(memOut) 
);
endmodule

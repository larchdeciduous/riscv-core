module riscvcore(
input clk,
//input rst,//sim

//gpio io
output [7:0] GPIO,
//led io
output [2:0] LED,
//sdram io
output SDRAM_CLK,
output SDRAM_CKE,
output SDRAM_RAS_N,
output SDRAM_CAS_N,
output SDRAM_WE_N,
output SDRAM_CS_N,
output [12:0] SDRAM_A,
output [1:0] SDRAM_BA,
inout [15:0] SDRAM_DQ,
output SDRAM_DQML,
output SDRAM_DQMH
);

wire [31:0] pc, instruction, aluOut, aluSrc1, aluSrc2, aluIn1, aluIn2, rs1Data, rs2Data, memOut;
wire [4:0] rs1Addr, rs2Addr, rdAddr;
wire [3:0] aluCtl;
wire [2:0] memSignWidth;
wire [1:0] rdSrc;
wire aluSrc1En, aluSrc2En, rdWrite, memWrite, memRead, memOp, memOpFinish, ifZero, stall, initFinish, memInit;
wire clk0, clk180, locked;

wire sdram_enable;
wire [23:0] sdram_addr;
wire sdram_write;
wire [31:0] sdram_wdata;
wire [1:0] sdram_dwidth;
wire [31:0] sdram_rdata;
wire sdram_ready;

assign initFinish = memInit;
assign stall = memOp & (~memOpFinish);
//TODO global rst  after pll locked  before every init  every need init should
//have a rst pin
reg rst, rst1delay;
always @(posedge clk) begin
    if(locked)
        rst1delay <= 1'b1;
    else begin
        rst <= 1'b1;
        rst1delay <= 0;
    end
    if(rst1delay) 
        rst <= 0;
end

pll pll1
(
.clkin(clk), // 25 MHz, 0 deg
.clkout0(clk0), // 25 MHz, 0 deg
.clkout1(clk180), // 25 MHz, 180 deg
.locked(locked)
);


/*
always @(*) begin
	case(rdSrc)
		2'b00: rdData = aluOut;
		2'b01: rdData = memOut;
		2'b10: rdData = pc + 32'h4;
	endcase
end
*/
// Remove the always @(*) block for rdData
wire [31:0] rdData;
assign rdData = (rdSrc == 2'b00) ? aluOut :
                (rdSrc == 2'b01) ? memOut :
                (pc + 32'h4);


assign aluIn1 = (aluSrc1En) ? aluSrc1 : rs1Data;
assign aluIn2 = (aluSrc2En) ? aluSrc2 : rs2Data;

instMem im(
.clk(clk0),
.addr(pc[11:0]),
.dataOut(instruction)
);

instf insFetch(
.clk(clk0),
.rst(~initFinish | rst),
.stall(stall),
.instruction(instruction),
.ifZero(ifZero),
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
.memRead(memRead),
.memSignWidth(memSignWidth)
);

registers rf(
.clk(clk0),
.rst(~initFinish | rst),
.stall(stall),
.rdWrite(rdWrite),
.rs1Addr(rs1Addr),
.rs2Addr(rs2Addr),
.rdAddr(rdAddr),
.rdData(rdData),
.rs1Data(rs1Data),
.rs2Data(rs2Data)
);

alu aluu(
.clk(clk0),
.ctl(aluCtl),
.src1(aluIn1),
.src2(aluIn2),
.result(aluOut),
.ifZero(ifZero)
);

datamem dm(
.clk(clk0),
.rst(rst),
.data(rs2Data),
.addr(aluOut),
.memRead(memRead),
.memWrite(memWrite),
.memSignWidth(memSignWidth),
.initFinish(memInit),
.op(memOp),
.opFinish(memOpFinish),
.dataOut(memOut),
//sdram
.sdram_enable(sdram_enable),
.sdram_addr(sdram_addr),
.sdram_write(sdram_write),
.sdram_wdata(sdram_wdata),
.sdram_dwidth(sdram_dwidth),
.sdram_rdata(sdram_rdata),
.sdram_ready(sdram_ready),
//io
.io_led(LED),
.io_gpio(GPIO)
);

sdram sdram1 (
.clk(clk0),
.clk180(clk180),
.clk25m(clk0),
.rst(rst),
.enable(sdram_enable),
.addr(sdram_addr),
.write(sdram_write),
.write_data(sdram_wdata),
.data_width(sdram_dwidth),
.read_data(sdram_rdata),
.ready(sdram_ready),

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
.SDRAM_DQMH(SDRAM_DQMH)
);

endmodule

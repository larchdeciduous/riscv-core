`default_nettype none
module riscvcore(
input clk,
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
output SDRAM_DQMH,
//hdmi io
output [3:0] gpdi_dp,
output [3:0] gpdi_dn
);

//core wire
wire [31:0] pc, nextPc, instruction, aluOut, aluSrc1, aluSrc2, aluIn1, aluIn2, rs1Data, rs2Data, memOut;
wire [4:0] rs1Addr, rs2Addr, rdAddr;
wire [3:0] aluCtl;
wire [2:0] memSignWidth;
wire [1:0] rdSrc;
wire aluSrc1En, aluSrc2En, rdWrite, memWrite, memRead, memOp, memOpFinish, ifZero, stall, initFinish, memInit, memIllegal;
wire clk0, clk0250, locked;

//sdram wire
wire sdram_enable;
wire [24:0] sdram_addr;
wire sdram_write;
wire [31:0] sdram_wdata;
wire [1:0] sdram_dwidth;
wire [31:0] sdram_rdata;
wire sdram_ready;

//frame_buffer wire
wire [11:0] fb_xpos, fb_ypos;
wire fb_color, fb_we, fb_re;
wire [1:0] fb_mask;
wire [15:0] fb_addr;
wire [31:0] fb_wdata;
wire [31:0] fb_rdata;

//hdmi_ctler wire
wire [23:0] hdmi_color;

//csr wire
wire [11:0] csr_addr;
wire [31:0] csr_wdata, csr_rdata, csr_cause, csr_trap_vector, csr_ret_addr, csr_wdataSrc1;
wire [1:0] csr_next_priv;
wire csr_write, csr_set, csr_clear, csr_trap_take, csr_mret, csr_sret, csr_wdataSrc1En;
wire csr_mtip, csr_interrupt_timer;

assign initFinish = memInit;
assign stall = memOp & (~memOpFinish);

reg rst;
reg [2:0] rstdelay;
always @(posedge clk) begin
    if(~locked) begin
        rstdelay <= 0;
        rst <= 1'b1;
    end
    else begin
        rst <= 1'b1;
        case(rstdelay)
            3'h0:
                rstdelay <= 3'h1;
            3'h1:
                rstdelay <= 3'h2;
            3'h2:
                rstdelay <= 3'h3;
            3'h3: begin
                rst <= 0;
                rstdelay <= 3'h3;
            end
            default: begin
                rstdelay <= 0;
                rst <= 1'b1;
            end
        endcase
    end
end

reg [1:0] priv;
always @(posedge clk0) begin
    if(rst)
        priv <= 2'b11;
    else
        priv <= csr_next_priv;
end

pll pll0
(
.clkin(clk), // 25 MHz, 0 deg
.clkout0(clk0250), // 250 MHz, 0 deg
.clkout1(clk0), // 25 MHz, 0 deg
.locked(locked)
);

wire [31:0] rdData;
assign rdData = (rdSrc == 2'b00) ? aluOut :
                (rdSrc == 2'b01) ? memOut :
                (rdSrc == 2'b10) ? (pc + 32'h4) :
                32'b0;

assign aluIn1 = (aluSrc1En) ? aluSrc1 : rs1Data;
assign aluIn2 = (aluSrc2En) ? aluSrc2 : rs2Data;
assign csr_wdata = (csr_wdataSrc1En) ? csr_wdataSrc1 : rs1Data;

instMem im(
.clk(clk0),
.addr(nextPc[11:0]),
.dataOut(instruction)
);

instf insFetch(
.clk(clk0),
.rst(~initFinish | rst),
.stall(stall),
.instruction(instruction),
.pc(pc),
.nextPc(nextPc),
//register
.rs1(rs1Addr),
.rs2(rs2Addr),
.rs1Data(rs1Data),
.rs2Data(rs2Data),
.rd(rdAddr),
.rdSrc(rdSrc),
.rdWrite(rdWrite),
//alu
.aluCtl(aluCtl),
.ifZero(ifZero),
.aluSrc1(aluSrc1),
.aluSrc1En(aluSrc1En),
.aluSrc2(aluSrc2),
.aluSrc2En(aluSrc2En),
//data memory
.memWrite(memWrite),
.memRead(memRead),
.memSignWidth(memSignWidth),
.memIllegal(memIllegal),
//csr
.current_priv(priv),
.csr_addr(csr_addr),
.csr_wdataSrc1(csr_wdataSrc1),
.csr_wdataSrc1En(csr_wdataSrc1En),
.csr_write(csr_write),
.csr_set(csr_set),
.csr_clear(csr_clear),
.csr_rdata(csr_rdata),
.csr_trap_take(csr_trap_take),
.csr_mret(csr_mret),
.csr_sret(csr_sret),
.csr_trap_pc(pc),
.csr_cause(csr_cause),
.csr_trap_vector(csr_trap_vector),
.csr_ret_addr(csr_ret_addr),
.csr_interrupt_timer(csr_interrupt_timer)
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
.clk25m(clk0),
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
.illegal(memIllegal),
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
.io_gpio(GPIO),
//fram_buffer
.fb_we(fb_we),
.fb_re(fb_re),
.fb_mask(fb_mask),
.fb_addr(fb_addr),
.fb_wdata(fb_wdata),
.fb_rdata(fb_rdata),
//csr
.csr_mtip(csr_mtip)
);

sdram sdram1 (
.clk(clk0),
.clk25m(clk0),
.rst(rst),
.enable(sdram_enable),
.addr(sdram_addr[24:1]),
.odd_access(sdram_addr[0]),
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

frame_buffer fb1(
.clk(clk0),
.rst(rst),
//hdmi
.xpos(fb_xpos),
.ypos(fb_ypos),
.color(fb_color),
//frame_buffer
.we(fb_we),
.re(fb_re),
.mask(fb_mask),
.addr(fb_addr),
.wdata(fb_wdata),
.rdata(fb_rdata)
);

assign hdmi_color = {24{fb_color}};

hdmi_ctler hdmi1 (
.clk_25mhz(clk0),
.clk_250mhz(clk0250),
.gpdi_dp(gpdi_dp),
.gpdi_dn(gpdi_dn),
.xpos(fb_xpos),
.ypos(fb_ypos),
.color(hdmi_color)
);

csr csr1(
.clk(clk0),
.rst(~initFinish | rst),

.addr(csr_addr),
.wdata(csr_wdata),
.write(csr_write),
.set(csr_set),
.clear(csr_clear),
.rdata(csr_rdata),

.trap_take(csr_trap_take),
.mret(csr_mret),
.sret(csr_sret),

.trap_pc(pc),
.trap_cause(csr_cause),

.trap_vector(csr_trap_vector),
.ret_addr(csr_ret_addr),
.current_priv(priv),
.next_priv(csr_next_priv),
.interrupt_timer(csr_interrupt_timer),
.mtip(csr_mtip)
);

endmodule

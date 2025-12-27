`default_nettype none
module csr(
input clk,
input rst,

input [11:0] addr,
input [31:0] wdata,
input write,
input set,
input clear,
output reg [31:0] rdata,

input trap_take,
input mret,
input sret,

input [31:0] trap_pc,
input [31:0] trap_cause,

output [31:0] trap_vector,
output [31:0] ret_addr,
input [1:0] current_priv,
output [1:0] next_priv
);

reg [31:0] mtvec;
reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mscratch;

reg [31:0] mstatus;
wire [31:0] medeleg; // must to zero: 11 14 16-31 to zero: 10
reg [31:0] r_medeleg;
assign medeleg = 0;
/* // future support s mode
assign medeleg[31:16] = 0;
assign medeleg[10] = 0;
assign medeleg[11] = 0;
assign medeleg[14] = 0;
assign medeleg[9:0] = r_medeleg[9:0];
assign medeleg[13:12] = r_medeleg[13:12];
*/

reg [31:0] stvec;
reg [31:0] sepc;
reg [31:0] scause;
reg [31:0] sscratch;

wire mie, mpie, spp;
wire [1:0] mpp;

assign mie = mstatus[3];
assign mpie = mstatus[7];
assign spp = mstatus[8];
assign mpp = mstatus[12:11];
always @(posedge clk) begin
    if(rst) begin
        mtvec <= 32'h00000200;
        mepc <= 0;
        mcause <= 0;
        mstatus <= 32'h0000_1880;
        r_medeleg <= 0;
    end
    else begin
        case({ (write | set | clear), trap_take, mret, sret})
            4'b1000: begin
                case(addr)
                    12'h300: mstatus<= (write) ? wdata :
                                        (set) ? (mstatus | wdata) :
                                                (mstatus & ~wdata);
                    12'h302: r_medeleg<= (write) ? wdata :
                                        (set) ? (mstatus | wdata) :
                                                (mstatus & ~wdata);
                    12'h305: mtvec  <= (write) ? wdata :
                                        (set) ? (mtvec | wdata) :
                                                (mtvec & ~wdata);
                    12'h340: mscratch<= (write) ? wdata :
                                        (set) ? (mtvec | wdata) :
                                                (mtvec & ~wdata);
                    12'h341: mepc   <= (write) ? wdata :
                                        (set) ? (mepc | wdata) :
                                                (mepc & ~wdata);
                    12'h342: mcause <= (write) ? wdata :
                                        (set) ? (mcause | wdata) :
                                                (mcause & ~wdata);
                    12'h105: stvec  <= (write) ? wdata :
                                        (set) ? (mtvec | wdata) :
                                                (mtvec & ~wdata);
                    12'h140: sscratch<= (write) ? wdata :
                                        (set) ? (mtvec | wdata) :
                                                (mtvec & ~wdata);
                    12'h141: sepc   <= (write) ? wdata :
                                        (set) ? (mepc | wdata) :
                                                (mepc & ~wdata);
                    12'h142: scause <= (write) ? wdata :
                                        (set) ? (mcause | wdata) :
                                                (mcause & ~wdata);
                    default: begin
                    end
                endcase
            end
            4'b0100: begin
                if(medeleg[trap_cause]) begin
                end
                else begin
                    mepc <= trap_pc;
                    mcause <= trap_cause;
                    mstatus[7] <= mie; //mpie
                    mstatus[3] <= 0; //mie
                    mstatus[12:11] <= current_priv; //mpp
                end
            end
            4'b0010: begin
                mstatus[3] <= mpie;//mie
                mstatus[7] <= 1'b1;//mpie
                mstatus[12:11] <= 2'b11;
            end
            4'b0001: begin
                mstatus[3] <= mpie;//mie
                mstatus[7] <= 1'b1;//mpie
                mstatus[12:11] <= 2'b11;
            end
            default: begin
            end
        endcase
    end
end


always @(*) begin
    case(addr)
        12'h300: rdata = mstatus;
        12'h302: rdata = medeleg;
        12'h305: rdata = mtvec;
        12'h340: rdata = mscratch;
        12'h341: rdata = mepc;
        12'h342: rdata = mcause;
        12'h105: rdata = stvec;
        12'h140: rdata = sscratch;
        12'h141: rdata = sepc;
        12'h142: rdata = scause;
        default: rdata = 0;
    endcase
end
always @(*) begin
    trap_vector = (medeleg[trap_cause]) ? stvec : mtvec;
    ret_addr = (medeleg[trap_cause]) ? sepc : mepc;
    if(mret)
        next_priv = mpp;
    else if(sret)
        next_priv = (spp) ? 2'b01 : 2'b00;
    else
        next_priv = current_priv;
end

endmodule

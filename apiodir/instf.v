`default_nettype none
module instf(
input clk,
input rst,
input stall,
input [31:0] instruction,
output reg [31:0] pc,
//register
output [4:0] rs1,
output [4:0] rs2,
input [31:0] rs1Data,
input [31:0] rs2Data,
output [4:0] rd,
output reg [1:0] rdSrc,
output reg rdWrite,
//alu
output reg [3:0] aluCtl,
input ifZero,
output reg [31:0] aluSrc1,
output reg aluSrc1En,
output reg [31:0] aluSrc2,
output reg aluSrc2En,
//data memory
output reg memWrite,
output reg memRead,
output [2:0] memSignWidth,
//csr
input [1:0] current_priv,
output [11:0] csr_addr,
output [31:0] csr_wdataSrc1,
output csr_wdataSrc1En,
output csr_write,
output csr_set,
output csr_clear,
input [31:0] csr_rdata,
output csr_trap_take,
output csr_mret,
output csr_sret,
output [31:0] csr_trap_pc,
output [31:0] csr_cause,
input [31:0] csr_trap_vector,
input [31:0] csr_ret_addr
);
wire [6:0] func7, opcode;
wire [2:0] func3;
wire [11:0] imme, immej;
wire [19:0] imme20, immej20;
wire [31:0] jumpTo, jumpToj, jumpToj20;

assign func7 = instruction[31:25];
assign rs2 = instruction[24:20];
assign rs1 = instruction[19:15];
assign func3 = instruction[14:12];
assign rd = instruction[11:7];
assign opcode = instruction[6:0];
assign imme = instruction[31:20];
assign imme20 = instruction[31:12];
assign immej = { instruction[31], instruction[7], instruction[30:25], instruction[11:8] };
assign immej20 = { instruction[31], instruction[19:12], instruction[20], instruction[30:21] };

assign jumpTo = { {21{imme[11]}}, imme[10:1], 1'b0 };
assign jumpToj = { {20{immej[11]}}, immej[10:0], 1'b0 };
assign jumpToj20 = { {12{immej20[19]}}, immej20[18:0], 1'b0 };
assign memSignWidth = func3;
reg [1:0] ifJump;
always @(posedge clk) begin
	if(rst)
		pc <= 0;
	else if(stall)
		pc <= pc;
    else if(csr_trap_take) begin
        pc <= csr_trap_vector;
    end
    else if(csr_mret | csr_sret) begin
        pc <= csr_ret_addr;
    end
	else begin
		case(ifJump)
			2'b00: pc <= pc + 32'h4;
			2'b01: pc <= rs1Data + jumpTo;
			2'b10: pc <= pc + jumpToj20;
			2'b11: pc <= pc + jumpToj;
		endcase
	end
end

wire csr_illegal_access;
assign csr_illegal_access = ( ((imme[11:8] == 4'h3) & (current_priv != 2'b11)) // m mode
                            | ((imme[11:8] == 4'h1) & (current_priv == 2'b00)) ); // s mode 

always @(*) begin
    //default if not change by opcode
    aluCtl = 0;
    ifJump = 0;
    aluSrc1 = 0;
    aluSrc1En = 0;
    aluSrc2 = 0;
    aluSrc2En = 0;
    rdWrite = 0;
    rdSrc = 0;
    memWrite = 0;
    memRead = 0;

    csr_cause = 0;
    csr_trap_take = 0;
    csr_mret = 0;
    csr_sret = 0;

    csr_addr = 0;
    csr_wdataSrc1 = 0;
    csr_wdataSrc1En = 0;
    csr_write = 0;
    csr_set = 0;
    csr_clear = 0;
	case(opcode)
	//R-type Instruction
		7'b0110011: begin
            aluCtl = 0;
			aluSrc1En = 0;
			aluSrc2En = 0;
			rdWrite = 1'b1;
			rdSrc = 2'b00;
            csr_trap_take = 0;
            csr_cause = 0;
			case(func3)
				3'b000: aluCtl = (func7[5]) ? 4'h1 : 4'h0;
				3'b001: aluCtl = 4'h2;
				3'b010: aluCtl = 4'h3;
				3'b011: aluCtl = 4'h4;
				3'b100: aluCtl = 4'h5;
				3'b101: aluCtl = (func7[5]) ? 4'h7 : 4'h6;
				3'b110: aluCtl = 4'h8;
				3'b111: aluCtl = 4'h9;
                default: begin // cause 2
                    csr_trap_take = 1'b1;
                    csr_cause = 32'h02;
                    rdWrite = 0;
                end
			endcase
		end

	//I-type instruction
		7'b0010011: begin
            aluCtl = 0;
			aluSrc1En = 0;
			aluSrc2 = { {21{imme[11]}}, imme[10:0] };
			aluSrc2En = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 2'b00;
            csr_trap_take = 0;
            csr_cause = 0;
			case(func3)
				3'b000: aluCtl = 4'h0;
				3'b001: aluCtl = 4'h2;
				3'b010: aluCtl = 4'h3;
				3'b011: aluCtl = 4'h4;
				3'b100: aluCtl = 4'h5;
				3'b101: aluCtl = func7[5] ? 4'h7 : 4'h6;
				3'b110: aluCtl = 4'h8;
				3'b111: aluCtl = 4'h9;
                default: begin // cause 2
                    csr_trap_take = 1'b1;
                    csr_cause = 32'h02;
                    rdWrite = 0;
                end
			endcase
		end

		7'b0000011: begin // LOAD
            aluCtl = 0;
			aluSrc1En = 0;
			aluSrc2 = { {21{imme[11]}}, imme[10:0] };
			aluSrc2En = 1'b1;
			memRead = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 2'b01;
		end	
		7'b1100111: begin //JALR
			ifJump = 2'b01;
			rdWrite = 1'b1;
			rdSrc = 2'b10; //pc+4
		end

	//S-type instruction
		7'b0100011: begin
            aluCtl = 0;
			aluSrc1En = 0;
			aluSrc2 = { {20{func7[6]}}, func7[6:0], rd };
			aluSrc2En = 1'b1;
			memWrite = 1'b1;
		end

	//U-type instruction
		7'b0110111: begin //LUI
            aluCtl = 0;
			aluSrc1 = 0;
			aluSrc1En = 1'b1;
			aluSrc2 = { imme20, {12{1'b0}} };
			aluSrc2En = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 0;
		end
		7'b0010111: begin //AUIPC
            aluCtl = 0;
			aluSrc1 = pc;
			aluSrc1En = 1'b1;
			aluSrc2 = { imme20, {12{1'b0}} };
			aluSrc2En = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 0;
		end
	//J-type instruction
		7'b1101111: begin //JAL
			ifJump = 2'b10;
			rdWrite = 1'b1;
			rdSrc = 2'b10; //pc+4
		end

      //SB-type instruction
		7'b1100011: begin
			aluSrc1En = 0;
			aluSrc2En = 0;
            csr_trap_take = 0;
            csr_cause = 0;
			case(func3)
				3'b000: begin // BEQ
					aluCtl = 4'h1;
					ifJump = ifZero ? 2'b11 : 2'b00;
				end
				3'b001: begin // BNE
					aluCtl = 4'h1;
					ifJump = ~ifZero ? 2'b11 : 2'b00;
				end
				3'b100: begin // BLT
					aluCtl = 4'h3;
					ifJump = ~ifZero ? 2'b11 : 2'b00;
				end
				3'b101: begin // BGE
					aluCtl = 4'h3;
					ifJump = ifZero ? 2'b11 : 2'b00;
				end
				3'b110: begin // BLTU
					aluCtl = 4'h4;
					ifJump = ~ifZero ? 2'b11 : 2'b00;
				end
				3'b111: begin // BGEU
					aluCtl = 4'h4;
					ifJump = ifZero ? 2'b11 : 2'b00;
				end
				default: begin // cause 2
                    csr_trap_take = 1'b1;
                    csr_cause = 32'h02;
					aluCtl = 4'h0;
					ifJump = 2'b00;
				end
			endcase
		end
        // System Instruction
        7'b1110011: begin
            csr_addr = 0;
            csr_wdataSrc1 = 0;
            csr_wdataSrc1En = 0;
            csr_write = 0;
            csr_set = 0;
            csr_clear = 0;
            rdWrite = 0;
            aluSrc1 = 0;
            aluSrc1En = 0;
            aluSrc2 = 0;
            aluSrc2En = 0;

            csr_mret = 0;
            csr_sret = 0;
            csr_trap_take = 0;
            csr_cause = 0;
            case(func3)
                3'b000: begin
                    csr_mret = 0;
                    csr_sret = 0;
                    csr_trap_take = 0;
                    csr_cause = 0;
                    case(imme)
                        12'h000: begin // ECALL
                            case(current_priv)
                                2'b00: csr_cause = 32'h08;
                                2'b01: csr_cause = 32'h09;
                                2'b11: csr_cause = 32'h0b;
                                default: csr_cause = 32'h08;
                            endcase
                            csr_trap_take = 1'b1;
                        end
                        12'h001: begin // EBREAK
                            csr_trap_take = 1'b1;
                            csr_cause = 32'h03;
                        end
                        12'h302: begin // MRET
                            if(current_priv == 2'b11)
                                csr_mret = 1'b1;
                            else begin // cause 2
                                csr_trap_take = 1'b1;
                                csr_cause = 32'h02;
                            end
                        end
                        12'h102: begin // SRET
                            if(current_priv != 2'b00)
                                csr_sret = 1'b1;
                            else begin // cause 2
                                csr_trap_take = 1'b1;
                                csr_cause = 32'h02;
                            end
                        end
                        12'h105: begin // WFI
                            //NOP
                        end
                        default: begin // cause 2
                            csr_trap_take = 1'b1;
                            csr_cause = 32'h02;
                        end
                    endcase
                end
                3'b001: begin // CSRRW
                    if(csr_illegal_access) begin
                        csr_addr = imme;
                        csr_wdataSrc1En = 0;
                        csr_write = 1'b1;
                        rdWrite = 1'b1;
                        aluSrc1 = csr_rdata;
                        aluSrc1En = 1'b1;
                        aluSrc2 = 0;
                        aluSrc2En = 1'b1;
                    end
                    else begin // cause 2
                        csr_trap_take = 1'b1;
                        csr_cause = 32'h02;
                    end
                end
                3'b010: begin // CSRRS
                    if(csr_illegal_access) begin
                        csr_addr = imme;
                        csr_wdataSrc1En = 0;
                        csr_set = 1'b1;
                        rdWrite = 1'b1;
                        aluSrc1 = csr_rdata;
                        aluSrc1En = 1'b1;
                        aluSrc2 = 0;
                        aluSrc2En = 1'b1;
                    end
                    else begin // cause 2
                        csr_trap_take = 1'b1;
                        csr_cause = 32'h02;
                    end
                end
                3'b011: begin // CSRRC
                    if(csr_illegal_access) begin
                        csr_addr = imme;
                        csr_wdataSrc1En = 0;
                        csr_clear = 1'b1;
                        rdWrite = 1'b1;
                        aluSrc1 = csr_rdata;
                        aluSrc1En = 1'b1;
                        aluSrc2 = 0;
                        aluSrc2En = 1'b1;
                    end
                    else begin // cause 2
                        csr_trap_take = 1'b1;
                        csr_cause = 32'h02;
                    end
                end
                3'b101: begin // CSRRWI
                    if(csr_illegal_access) begin
                        csr_addr = imme;
                        csr_wdataSrc1 = { 27'b0, rs1 };
                        csr_wdataSrc1En = 1'b1;
                        csr_write = 1'b1;
                        rdWrite = 1'b1;
                        aluSrc1 = csr_rdata;
                        aluSrc1En = 1'b1;
                        aluSrc2 = 0;
                        aluSrc2En = 1'b1;
                    end
                    else begin // cause 2
                        csr_trap_take = 1'b1;
                        csr_cause = 32'h02;
                    end
                end
                3'b110: begin // CSRRSI
                    if(csr_illegal_access) begin
                        csr_addr = imme;
                        csr_wdataSrc1 = { 27'b0, rs1 };
                        csr_wdataSrc1En = 1'b1;
                        csr_set = 1'b1;
                        rdWrite = 1'b1;
                        aluSrc1 = csr_rdata;
                        aluSrc1En = 1'b1;
                        aluSrc2 = 0;
                        aluSrc2En = 1'b1;
                    end
                    else begin // cause 2
                        csr_trap_take = 1'b1;
                        csr_cause = 32'h02;
                    end
                end
                3'b111: begin // CSRRCI
                    if(csr_illegal_access) begin
                        csr_addr = imme;
                        csr_wdataSrc1 = { 27'b0, rs1 };
                        csr_wdataSrc1En = 1'b1;
                        csr_clear = 1'b1;
                        rdWrite = 1'b1;
                        aluSrc1 = csr_rdata;
                        aluSrc1En = 1'b1;
                        aluSrc2 = 0;
                        aluSrc2En = 1'b1;
                    end
                    else begin // cause 2
                        csr_trap_take = 1'b1;
                        csr_cause = 32'h02;
                    end
                end
                default: begin // cause 2
                    csr_cause = 32'h02;
                    csr_trap_take = 1'b1;
                end
            endcase
        end

		default: begin // cause 2
            csr_cause = 32'h02;
            csr_trap_take = 1'b1;
		end

	endcase
end


				
endmodule

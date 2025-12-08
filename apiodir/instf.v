module insf(
input clk,
input rst,
input stall,
input [31:0] instruction,
output reg [31:0] pc,
output [4:0] rs1,
output [4:0] rs2,
input [31:0] rs1Data,
input [31:0] rs2Data,
output [4:0] rd,
output reg [3:0] aluCtl,
output reg [31:0] aluSrc1,
output reg aluSrc1En,
output reg [31:0] aluSrc2,
output reg aluSrc2En,
output reg [1:0] rdSrc,
output reg rdWrite,
output reg memWrite,
output reg memRead,
output reg [1:0]ifJump
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
assign jumpToj20 = { {11{immej20[19]}}, immej20[18:0], 1'b0 };
always @(posedge clk) begin
	if(rst)
		pc <= 0;
	else if(stall)
		pc <= pc;
	else begin
		case(ifJump)
			2'b00: pc <= pc + 4'h4;
			2'b01: pc <= pc + jumpTo;
			2'b10: pc <= pc + jumpToj20;
			2'b11: pc <= pc + jumpToj;
		endcase
	end
end



always @(*) begin
	//R-type Instruction
	case(opcode)
		7'b0110011: begin
			//aluCtl = 0;
			ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			aluSrc2 = 0;
			aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			memRead = 0;

			rdWrite = 1'b1;
			rdSrc = 2'b00;
			case({ func7[5], func3 })
				4'b0_000: aluCtl = 4'h0;
				4'b1_000: aluCtl = 4'h1;
				4'b0_001: aluCtl = 4'h2;
				4'b0_010: aluCtl = 4'h3;
				4'b0_011: aluCtl = 4'h4;
				4'b0_100: aluCtl = 4'h5;
				4'b0_101: aluCtl = 4'h6;
				4'b1_101: aluCtl = 4'h7;
				4'b0_110: aluCtl = 4'h8;
				4'b0_111: aluCtl = 4'h9;
			endcase
		end

	//I-type instruction
		7'b0010011: begin
			//aluCtl = 0;
			ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			//aluSrc2 = 0;
			//aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			memRead = 0;

			aluSrc2 = { {21{imme[11]}}, imme[10:0] };
			aluSrc2En = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 2'b00;
			case(func3)
				3'b000: aluCtl = 4'h0;
				3'b001: aluCtl = 4'h2;
				3'b010: aluCtl = 4'h3;
				3'b011: aluCtl = 4'h4;
				3'b100: aluCtl = 4'h5;
				3'b101: aluCtl = func7[5] ? 4'h7 : 4'h6;
				3'b110: aluCtl = 4'h8;
				3'b111: aluCtl = 4'h9;
			endcase
		end
		7'b0000011: begin //LB LH LW LBU LHU
			//aluCtl = 0;
			ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			//aluSrc2 = 0;
			//aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			//memRead = 0;

			aluCtl = 4'h0;
			aluSrc2 = { {21{imme[11]}}, imme[10:0] };
			aluSrc2En = 1'b1;
			memRead = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 2'b01;
		end	
		7'b1100111: begin //JALR
			//aluCtl = 0;
			//ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			aluSrc2 = 0;
			aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			memRead = 0;

			aluCtl = 4'h0;
			rdWrite = 1'b1;
			rdSrc = 2'b10;
			ifJump = 2'b01;
		end

	//S-type instruction
		7'b0100011: begin
			aluCtl = 0;
			ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			//aluSrc2 = 0;
			//aluSrc2En = 0;
			rdWrite = 0;
			rdSrc = 0;
			//memWrite = 0;
			memRead = 0;

			aluSrc2 = { {20{func7[6]}}, func7[5:0], rd };
			aluSrc2En = 1'b1;
			memWrite = 1'b1;
		end

	//U-type instruction
		7'b0110111: begin //LUI
			//aluCtl = 0;
			ifJump = 0;
			//aluSrc1 = 0;
			//aluSrc1En = 0;
			//aluSrc2 = 0;
			//aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			memRead = 0;

			aluCtl = 0;
			aluSrc1 = 0;
			aluSrc1En = 1'b1;
			aluSrc2 = { imme20, {12{1'b0}} };
			aluSrc2En = 1'b1;
			rdWrite = 1'b1;
			rdSrc = 0;
		end
		7'b0010111: begin //AUIPC
			//aluCtl = 0;
			ifJump = 0;
			//aluSrc1 = 0;
			//aluSrc1En = 0;
			//aluSrc2 = 0;
			//aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			memRead = 0;

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
			//aluCtl = 0;
			//ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			aluSrc2 = 0;
			aluSrc2En = 0;
			//rdWrite = 0;
			//rdSrc = 0;
			memWrite = 0;
			memRead = 0;

			aluCtl = 0;
			ifJump = 2'b10;
			rdWrite = 1'b1;
			rdSrc = 2'b10;
		end

      //SB-type instruction
		7'b1100011: begin
			//aluCtl = 0;
			//ifJump = 0;
			aluSrc1 = 0;
			aluSrc1En = 0;
			aluSrc2 = 0;
			aluSrc2En = 0;
			rdWrite = 0;
			rdSrc = 0;
			memWrite = 0;
			memRead = 0;

			aluCtl = 4'b0;
			case(func3)
				3'b000: ifJump = (rs1Data == rs2Data) ? 2'b11 : 2'b0;
				3'b001: ifJump = (rs1Data != rs2Data) ? 2'b11 : 2'b0;
				3'b100: ifJump = ($signed(rs1Data) < $signed(rs2Data)) ? 2'b11 : 2'b0;
				3'b101: ifJump = ($signed(rs1Data) >= $signed(rs2Data)) ? 2'b11 : 2'b0;
				3'b110: ifJump = (rs1Data < rs2Data) ? 2'b11 : 2'b0;
				3'b111: ifJump = (rs1Data >= rs2Data) ? 2'b11 : 2'b0;
			endcase
		end
		default: begin
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
		end

	endcase
end


				
endmodule


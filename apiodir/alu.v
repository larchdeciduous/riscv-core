module alu (
input clk,
input [3:0] ctl,
input [31:0] src1,
input [31:0] src2,
output reg [31:0] result,
output ifZero
);

always @(*) begin
	case(ctl)
		4'h0: result = src1 + src2;
		4'h1: result = src1 - src2;
		4'h2: result = src1 << src2[4:0];
		4'h3: result = $signed(src1) < $signed(src2) ? 32'b1 : 32'b0;
		4'h4: result = src1 < src2 ? 32'b1 : 32'b0;
		4'h5: result = src1 ^ src2;
		4'h6: result = src1 >> src2[4:0];
		4'h7: result = $signed(src1) >>> src2[4:0];
		4'h8: result = src1 | src2;
		4'h9: result = src1 & src2;
		default: result = {31{1'b1}};
	endcase
end

assign ifZero = result ? 1'b0 : 1'b1;


endmodule

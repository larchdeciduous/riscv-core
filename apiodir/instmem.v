`default_nettype none
module instMem #
(
parameter WIDTH = 2048,
parameter ADDR_WIDTH = $clog2(WIDTH)
)
(
input clk,
input [31:0] addr,
output reg [31:0] dataOut,
//datamem
input [31:0] datamem_addr,
output reg [31:0] datamem_dataOut
);


reg [15:0] rom [WIDTH-1:0];

initial begin
	$readmemh("inst.rom", rom, 0, WIDTH-1);
end

always @(posedge clk) begin
    dataOut[15:0] <=    rom[addr[ADDR_WIDTH:1]];
    dataOut[31:16] <=   rom[addr[ADDR_WIDTH:1] + 1];
    datamem_dataOut[15:0] <=    rom[datamem_addr[ADDR_WIDTH:1]];
    datamem_dataOut[31:16] <=   rom[datamem_addr[ADDR_WIDTH:1] + 1];
end

endmodule

module frame_buffer(
input clk,
input rst,
//hdmi
input [11:0] xpos,
input [11:0] ypos,
output color,
//frame_buffer
input we,
input re,
input [1:0] mask,
input [15:0] addr,
input [31:0] wdata,
output reg [31:0] rdata
);

wire [3:0] dmask;
reg [31:0] graphicMem [9599:0];

/*
integer i;
initial begin
    for (i = 0; i < 9600; i = i + 1) begin
        graphicMem[i] = 32'd0;
    end
end
*/

assign dmask = (mask[1]) ? 4'b1111 : (mask[0]) ? 4'b0011 : 4'b0001;

always @(posedge clk) begin
    if(rst)
        rdata <= 0;
    else if (re)
        rdata <= graphicMem[addr[15:2]];
    else if (we) begin
        if (dmask[0]) graphicMem[addr[15:2]][7:0]   <= wdata[7:0];
        if (dmask[1]) graphicMem[addr[15:2]][15:8]  <= wdata[15:8];
        if (dmask[2]) graphicMem[addr[15:2]][23:16] <= wdata[23:16];
        if (dmask[3]) graphicMem[addr[15:2]][31:24] <= wdata[31:24];
    end
end

function [31:0] pos;
    input [31:0] x, y;
    begin
        pos = (y * 32'd640) + x;
    end
endfunction

reg [31:0] r_color;
wire [31:0] paddr;
assign paddr = pos({20'b0, xpos}, {20'b0, ypos});
always @(negedge clk) begin
    if(rst)
        r_color <= 0;
    else
        r_color <= graphicMem[paddr[18:5]];
end
assign color = r_color[paddr[4:0]];

endmodule

module datamem(
input clk,
input rst,
input [31:0] data,
input [31:0] addr,
input memRead,
input memWrite,
input [2:0] memSignWidth,
output reg initFinish,
output op,
output reg opFinish,
output reg [31:0] dataOut, //wire
//sdram
output reg sdram_enable,
output [23:0] sdram_addr,
output reg sdram_write,
output [31:0] sdram_wdata,
output [1:0] sdram_dwidth,
input [31:0] sdram_rdata,
input sdram_ready,
//io
output reg [2:0] io_led,
output reg [7:0] io_gpio
);

reg [31:0] r_sdram_rdata;
assign op = memRead | memWrite;
assign sdram_wdata = data;
assign sdram_addr = addr[23:0];
assign sdram_dwidth = memSignWidth[1:0];
always @(*) begin
    case(memSignWidth[1:0])
        2'b00: begin
            dataOut[7:0] = r_sdram_rdata[7:0];
            dataOut[31:8] = (memSignWidth[2]) ? 24'b0 : {24{r_sdram_rdata[7]}};
        end
        2'b01: begin
            dataOut[15:0] = sdram_rdata[15:0];
            dataOut[31:16] = (memSignWidth[2]) ? 16'b0 : {16{r_sdram_rdata[15]}};
        end
        default: begin
            dataOut = r_sdram_rdata;
        end
    endcase
end

reg [1:0] status;
always @(posedge clk) begin
    if(rst) begin
        status <= 0; opFinish <= 0; initFinish <= 0; io_led <= 0; io_gpio <= 0;
        sdram_enable <= 0;
        sdram_write <= 0;
    end
    else begin
        case (status)
            2'd0: begin
                opFinish <= 0;
                sdram_enable <= 0;
                sdram_write <= 0;
                io_led <= 0; io_gpio <= 0;

                initFinish <= 0;
                if(sdram_ready) begin
                    status <= 2'd1;
                    initFinish <= 1'b1;
                end
            end
            2'd1: begin // waitting
                opFinish <= 0;
                io_led <= io_led;
                io_gpio <= io_gpio;
                if(addr[31:24] >= 8'h80) begin
                    sdram_enable <= memRead | memWrite;
                    sdram_write <= memWrite;
                end
                else if(addr[31:24] == 8'h10) begin
                    sdram_enable <= 0;
                    sdram_write <= 0;
                    if(addr[23:0] == 0)
                        io_led <= data[2:0];
                    else if(addr[23:0] == 24'h000001)
                        io_gpio <= data[7:0];
                    status <= 2'd2;
                end
                if(~sdram_ready) begin
                    status <= 2'd2;
                end
            end
            2'd2: begin
                sdram_enable <= 0;
                sdram_write <= 0;
                if(sdram_ready) begin
                    status <= 2'd3;
                    opFinish <= 1'b1;
                    r_sdram_rdata <= sdram_rdata;
                end
            end
            2'd3: begin // wait pc go next before return to waitting
                status <= 2'd1;
            end
                    
        endcase
    end
end



endmodule

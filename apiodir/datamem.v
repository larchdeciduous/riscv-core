module datamem(
input clk,
input clk25m,
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
output reg [7:0] io_gpio,
//fram_buffer
output reg fb_we,
output reg fb_re,
output [1:0] fb_mask,
output [15:0] fb_addr,
output [31:0] fb_wdata,
input [31:0] fb_rdata,
//csr
output reg csr_mtip
);

reg [63:0] mtime, mtimecmp;
always @(posedge clk25m) begin
    if(rst)
        mtime <= 0;
    else
        mtime <= mtime + 64'b1;

    csr_mtip = mtime >= mtimecmp;
end

reg odd_access;
reg [31:0] r_rdata;
assign op = memRead | memWrite;
assign sdram_wdata = data;
assign sdram_addr = addr[23:0];
assign sdram_dwidth = memSignWidth[1:0];
assign fb_wdata = data;
assign fb_addr = addr[15:0];
assign fb_mask = memSignWidth[1:0];
always @(*) begin
    case(memSignWidth[1:0])
        2'b00: begin //byte
            if(odd_access) begin
                dataOut[7:0] = r_rdata[15:8];
                dataOut[31:16] = (memSignWidth[2]) ? 24'b0 : {24{r_rdata[15]}};
            end
            else begin
                dataOut[7:0] = r_rdata[7:0];
                dataOut[31:8] = (memSignWidth[2]) ? 24'b0 : {24{r_rdata[7]}};
            end
        end
        2'b01: begin //halfword
            if(odd_access) begin
                dataOut[15:0] = sdram_rdata[23:8];
                dataOut[31:16] = (memSignWidth[2]) ? 16'b0 : {16{r_rdata[23]}};
            end
            else begin
                dataOut[15:0] = sdram_rdata[15:0];
                dataOut[31:16] = (memSignWidth[2]) ? 16'b0 : {16{r_rdata[15]}};
            end
        end
        default: begin
            dataOut = r_rdata;
        end
    endcase
end

reg [1:0] status;
always @(posedge clk) begin
    if(rst) begin
        status <= 0; opFinish <= 0; initFinish <= 0; io_led <= 0; io_gpio <= 0;
        sdram_enable <= 0;
        sdram_write <= 0;
        mtimecmp <= 64'hffff_ffff_ffff_ffff;
        odd_access <= 0;
    end
    else begin
        case (status)
            2'd0: begin
                opFinish <= 0;
                sdram_enable <= 0;
                sdram_write <= 0;
                io_led <= 0; io_gpio <= 0;
                odd_access <= 0;

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
                if (memRead | memWrite) begin
                    sdram_enable <= 0;
                    sdram_write <= 0;
                    fb_re <= 0;
                    fb_we <= 0;
                    odd_access <= 0;
                    status <= 2'd1;
                    case(addr[31:24])
                        8'h10: begin // gpio led
                            if(addr[23:0] == 0)
                                io_led <= data[2:0];
                            else if(addr[23:0] == 24'h000001)
                                io_gpio <= data[7:0];
                            status <= 2'd2;
                        end
                        8'h20: begin
                            if(memRead) begin
                                case(addr[23:0])
                                    24'h004000: r_rdata <= mtimecmp[31:0];
                                    24'h004004: r_rdata <= mtimecmp[63:32];
                                    24'h00bff8: r_rdata <= mtime[31:0];
                                    24'h00bffc: r_rdata <= mtime[63:32];
                                    default: r_rdata = 0;
                                endcase
                            end
                            else if (memWrite) begin
                                case(addr[23:0])
                                    24'h004000: mtimecmp[31:0] <= data;
                                    24'h004004: mtimecmp[63:32] <= data;
                                    default: begin
                                    end
                                endcase
                            end
                        end
                        8'h21: begin // graphicMem
                            fb_re <= memRead;
                            fb_we <= memWrite;
                            status <= 2'd2;
                        end

                        8'h80: begin // sdram
                            sdram_enable <= 1'b1;
                            sdram_write <= memWrite;
                            odd_access <= 1'b1;
                        end
                        default: begin
                            sdram_enable <= 0;
                            sdram_write <= 0;
                            fb_re <= 0;
                            fb_we <= 0;
                            status <= 2'd1;
                            odd_access <= 0;
                        end
                    endcase
                    if(~sdram_ready) begin
                        status <= 2'd2;
                    end
                end
            end
            2'd2: begin
                sdram_enable <= 0;
                sdram_write <= 0;
                fb_re <= 0;
                fb_we <= 0;
                if(sdram_ready) begin
                    status <= 2'd3;
                    opFinish <= 1'b1;
                    r_rdata <= (addr[31:24] == 8'h80) ? sdram_rdata : 32'b0;
                end
            end
            2'd3: begin // wait pc go next before return to waitting, or get graphic data
                r_rdata <= (addr[31:24] == 8'h20) ? fb_rdata : 32'b0;
                status <= 2'd1;
            end
                    
        endcase
    end
end



endmodule

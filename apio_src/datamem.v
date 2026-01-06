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
output illegal,
output [31:0] illegalCause,
//instmem
input [31:0] instmem_data,
//sdram
output reg sdram_enable,
output [24:0] sdram_addr,
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
output reg csr_mtip,
//uart
output reg [31:0] uart_wdata,
output reg uart_we,
input uart_full
);

localparam INIT = 3'd0,
            IDLE = 3'd1,
            FAST_RETURN = 3'd2,
            MEM_FB1 = 3'd3,
            MEM_FB2 = 3'd4,
            UART_FULL = 3'd5,
            INSTMEM = 3'd6;

reg [15:0] instrom [2048:0];
initial begin
    $readmemh("inst.rom", instrom, 0, 1023);
end

reg [63:0] mtime, mtimecmp;
always @(posedge clk25m) begin
    if(rst)
        mtime <= 0;
    else
        mtime <= mtime + 64'b1;

    csr_mtip = mtime >= mtimecmp;
end
assign op = memWrite | memRead;
//reg readOp, memOp, fbOp, uartOp;
//assign op = memOp | fbOp | uartOp | readOp;
//always @(*) begin
//    readOp = 0;
//    memOp = 0;
//    fbOp = 0;
//    uartOp = 0;
//    if(memWrite) begin
//        if ((addr[31:24] == 8'h80) | (addr[31:24] == 8'h80))
//            memOp = 1'b1;
//        if(addr[31:24] == 8'h21)
//            fbOp = 1'b1;
//        if(uart_full & (addr[31:8] == 24'h200020))
//            uartOp = 1'b1;
//    end
//    else if(memRead)
//        readOp = 1'b1;
//end
        


reg odd_access;
reg [31:0] r_rdata;
assign sdram_wdata = data;
assign sdram_addr = addr[24:0];
assign sdram_dwidth = memSignWidth[1:0];
assign fb_wdata = data;
assign fb_addr = addr[15:0];
assign fb_mask = memSignWidth[1:0];
always @(*) begin
    case(memSignWidth[1:0])
        2'b00: begin //byte
            if(odd_access) begin
                dataOut[7:0] = r_rdata[15:8];
                dataOut[31:8] = (memSignWidth[2]) ? 24'b0 : {24{r_rdata[15]}};
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
assign illegal = addr[0] & (memSignWidth[1:0] == 2'b10) & ((addr[31:24] == 8'h80) | (addr[31:24] == 8'h81));

reg [2:0] status;
always @(posedge clk) begin
    if(rst) begin
        status <= INIT; opFinish <= 0; initFinish <= 0; io_led <= 0; io_gpio <= 0;
        sdram_enable <= 0;
        sdram_write <= 0;
        mtimecmp <= 64'hffff_ffff_ffff_ffff;
        odd_access <= 0;
        r_rdata <= 0;
        
    end
    else begin
        case (status)
            INIT: begin
                opFinish <= 0;
                sdram_enable <= 0;
                sdram_write <= 0;
                io_led <= 0; io_gpio <= 0;
                odd_access <= 0;
                uart_wdata <= 0;
                uart_we <= 0;

                initFinish <= 0;
                if(sdram_ready) begin
                    status <= IDLE;
                    initFinish <= 1'b1;
                end
            end
            IDLE: begin // waitting
                opFinish <= 0;
                io_led <= io_led;
                sdram_enable <= 0;
                sdram_write <= 0;
                fb_re <= 0;
                fb_we <= 0;
                odd_access <= 0;
                uart_wdata <= 0;
                uart_we <= 0;
                status <= IDLE;
                if (memRead | memWrite) begin
                    opFinish <= 0;
                    sdram_enable <= 0;
                    sdram_write <= 0;
                    fb_re <= 0;
                    fb_we <= 0;
                    odd_access <= 0;
                    uart_wdata <= 0;
                    uart_we <= 0;
                    status <= IDLE;
                    casez(addr[31:16]) // may future : case(1'b1) (addr[31:24]==8'h10): begin end endcase
                        16'h0000: begin
                            status <= INSTMEM;
                            odd_access <= addr[0];
                        end
                        16'h2000: begin
                            opFinish <= 1'b1;
                            status <= FAST_RETURN;
                            if(memRead) begin
                                case(addr[15:0])
                                    16'h0000: r_rdata <= { 29'b0, io_led };
                                    16'h1000: r_rdata <= { 24'b0, io_gpio };
                                    16'h4000: r_rdata <= mtimecmp[31:0];
                                    16'h4004: r_rdata <= mtimecmp[63:32];
                                    16'hbff8: r_rdata <= mtime[31:0];
                                    16'hbffc: r_rdata <= mtime[63:32];
                                    default: r_rdata = 0;
                                endcase
                            end
                            else if (memWrite) begin
                                case(addr[15:0])
                                    16'h0000: io_led <= data[2:0];
                                    16'h1000: io_gpio <= data[7:0];
                                    16'h2000: begin
                                        uart_wdata <= data;
                                        status <= (uart_full) ? UART_FULL : FAST_RETURN;
                                        uart_we <= (uart_full) ? 1'b0 : 1'b1;
                                        opFinish <= (uart_full) ? 1'b0 : 1'b1;
                                    end
                                    16'h4000: mtimecmp[31:0] <= data;
                                    16'h4004: mtimecmp[63:32] <= data;
                                    default: begin
                                    end
                                endcase
                            end
                        end
                        16'h2100: begin // graphicMem
                            fb_re <= memRead;
                            fb_we <= memWrite;
                            status <= MEM_FB1;
                        end

                        { 4'h8, 4'b000z, 8'hzz }: begin // sdram 80-81
                            sdram_enable <= 1'b1;
                            sdram_write <= memWrite;
                            odd_access <= addr[0];
                        end
                        default: begin
                            sdram_enable <= 0;
                            sdram_write <= 0;
                            fb_re <= 0;
                            fb_we <= 0;
                            status <= IDLE;
                            odd_access <= 0;
                        end
                    endcase
                    if(~sdram_ready) begin
                        status <= MEM_FB1;
                    end
                end
            end
            FAST_RETURN: begin // fast return
                sdram_enable <= 0;
                sdram_write <= 0;
                fb_re <= 0;
                fb_we <= 0;
                odd_access <= 0;
                uart_wdata <= 0;
                uart_we <= 0;
                opFinish <= 0;
                status <= IDLE;
            end
            MEM_FB1: begin
                sdram_enable <= 0;
                sdram_write <= 0;
                fb_re <= 0;
                fb_we <= 0;
                if(sdram_ready) begin
                    status <= MEM_FB2;
                    opFinish <= 1'b1;
                    r_rdata <= (addr[31:24] == 8'h80) ? sdram_rdata : r_rdata;
                end
            end
            MEM_FB2: begin // wait pc go next before return to waitting
                r_rdata <= (addr[31:24] == 8'h20) ? fb_rdata : r_rdata;
                status <= IDLE;
                opFinish <= 0;
            end
            UART_FULL: begin
                if(~uart_full) begin
                    uart_wdata <= data;
                    uart_we <= 1'b1;
                    opFinish <= 1'b1;
                    status <= FAST_RETURN;
                end
                else begin
                    uart_wdata <= data;
                    uart_we <= 0;
                    opFinish <= 0;
                    status <= UART_FULL;
                end
            end
            INSTMEM: begin
                r_rdata <= instmem_data;
                opFinish <= 1'b1;
                status <= FAST_RETURN;
            end
            default: begin
                status <= INIT;
            end
                    
        endcase
    end
end



endmodule

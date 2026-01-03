module sdram (
input clk,
input clk25m,
input rst,
input enable,
input [23:0] addr, //24 bit for 16bit data
input odd_access, // support byte halfword, not word
input write,
input [31:0] write_data,
input [1:0] data_width, // 00byte 01halfword 10word
output [31:0] read_data,
output reg ready,

output SDRAM_CLK,
output reg SDRAM_CKE,
output SDRAM_RAS_N,
output SDRAM_CAS_N,
output SDRAM_WE_N,
output SDRAM_CS_N,
output reg [12:0] SDRAM_A,
output reg [1:0] SDRAM_BA,
inout [15:0] SDRAM_DQ,
output SDRAM_DQML,
output SDRAM_DQMH
);
reg [15:0] r_sdram [40959:0];
/*
integer i;
initial begin
end
*/

reg [7:0] init_delay;
reg init_delay_en;
reg init_delay_finish;
always @(posedge clk25m) begin
    if(rst) begin
        init_delay <= 0;
        init_delay_finish <= 0;
    end
    else if(init_delay_en) begin
        init_delay <= init_delay + 8'b1;
        init_delay_finish <= (init_delay >= 8'hbf);
    end
    else begin
        init_delay <= init_delay;
        init_delay_finish <= (init_delay >= 8'hbf);
    end
end


reg [15:0] r_addr;
reg [31:0] r_write_data, r_read_data;
wire [31:0] write_data_odd;
reg [1:0] r_data_width;
reg r_odd_access;
reg [3:0] status;
assign read_data = r_read_data;
assign write_data_odd = (odd_access) ? { write_data[23:0], 8'b0 } : write_data;
integer i;
always @(posedge clk) begin
    if(rst) begin
        for (i = 0; i < 4096; i = i + 1) begin
            r_sdram[i] = 0;
        end
        ready <= 0;
        status <= 0;
        init_delay_en <= 0;
        r_addr <= 0;
        r_write_data <= 0;
        r_data_width <= 0;
        r_odd_access <= 0;
        r_read_data <= 0;
    end
    else begin
        case(status)
            4'h0: begin
                ready <= 0;
                init_delay_en <= 1'b1;
                if(init_delay_finish) begin
                    status <= 4'h1;
                    init_delay_en <= 0;
                end
            end
            4'h1: begin
                ready <= 1'b1;
                status <= 4'h1;
                if(enable) begin
                    ready <= 0;
                    status <= (write) ? 4'h4 : 4'h2;
                    r_addr <= addr[15:0];
                    r_write_data <= write_data_odd;
                    r_data_width <= data_width;
                    r_odd_access <= odd_access;
                end
            end
            4'h2: begin //read
                r_read_data[15:0] <= r_sdram[r_addr[15:0]];
                status <= 4'h3;
            end
            4'h3: begin
                r_read_data[31:16] <= r_sdram[r_addr[15:0] + 1];
                status <= 4'h6;
            end
            4'h4: begin //write
                r_sdram[r_addr[15:0]] <= r_write_data[15:0];
                status <= 4'h5;
            end
            4'h5: begin
                r_sdram[r_addr[15:0] + 1] <= r_write_data[31:16];
                status <= 4'h6;
            end
            4'h6: begin //wait for safe
                status <= 4'h7;
            end
            4'h7: begin
                status <= 4'h1;
                ready <= 1'b1;
            end
            default: begin
                status <= 0;
            end
        endcase
    end
end
endmodule


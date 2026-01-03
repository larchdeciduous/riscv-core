module uart
#(
    parameter DEPTH = 128,
    parameter UART_BAUD_DIV = 217,
    parameter WIDTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)
( // tx only for now
input clk,
input rst,
input [31:0] wdata,
input we,
output full,
output tx
);


reg re;
reg [WIDTH-1:0] r_fifo [DEPTH-1:0];

reg [PTR_WIDTH:0] p_write, p_read;

reg [3:0] shift_cnt;
reg [WIDTH+2:0] txdata;
reg [7:0] shift_wait_cnt;
reg shift_wait;
reg shift_wait_en;
reg busy;
always @(posedge clk) begin
    if(rst)
        shift_wait_cnt <= 0;
    else if(shift_wait_en)
        shift_wait_cnt <= shift_wait_cnt + 1;
    else 
        shift_wait_cnt <= 0;

    shift_wait <= (shift_wait_cnt == UART_BAUD_DIV);
end

wire empty;
assign empty = (p_write == p_read);
assign full = ( (p_write[PTR_WIDTH] != p_read[PTR_WIDTH]) &
                (p_write[PTR_WIDTH-1:0] == p_read[PTR_WIDTH-1:0]));
assign tx = txdata[0];
always @(posedge clk) begin
    //fifo
    if(rst) begin
        p_write = 0;
        p_read = 0;
    end
    else begin
        if(we & ~full) begin
            r_fifo[p_write[PTR_WIDTH-1:0]] <= wdata[7:0];
            p_write <= p_write + 1;
        end
        if(re & ~empty) begin
            /*
            txdata <= { 2'b11, r_fifo[ p_read[PTR_WIDTH-1:0] ][31:24], 1'b0,
                        2'b11, r_fifo[ p_read[PTR_WIDTH-1:0] ][23:16], 1'b0,
                        2'b11, r_fifo[ p_read[PTR_WIDTH-1:0] ][15:8],  1'b0,
                        2'b11, r_fifo[ p_read[PTR_WIDTH-1:0] ][7:0],   1'b0 };
            */
            txdata <= { 2'b11, r_fifo[ p_read[PTR_WIDTH-1:0] ][7:0], 1'b0 };
            p_read <= p_read + 1;
        end
    end

    //uart tx
    if(rst) begin
        txdata <= 11'b111_1111_1111;
        shift_cnt <= 0;
        shift_wait_en <= 0;
        busy <= 0;
        re <= 0;
    end
    else begin
        if(~empty & ~busy) begin
            busy <= 1;
            re <= 1;
            shift_cnt <= 0;
            shift_wait_en <= 0;
        end
        else if(busy) begin
            re <= 0;
            shift_wait_en <= 1;
            if(shift_wait) begin
                txdata <= { 1'b1, txdata[10:1] };
                shift_cnt <= shift_cnt + 1;
                shift_wait_en <= 0;
            end
            if(shift_wait & (shift_cnt == (WIDTH+2)))
                busy <= 0;
        end
        else begin //idle
            txdata <= 11'b111_1111_1111;
            shift_cnt <= 0;
            shift_wait_en <= 0;
            busy <= 0;
            re <= 0;
        end
    end




end


endmodule

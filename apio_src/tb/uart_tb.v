module uart_tb();

reg clk = 0;
always #20 clk = ~clk;
reg rst, we;
reg [31:0] wdata;
wire full, tx;

uart
#(
    .UART_BAUD_DIV(3)
)
uart1
( // tx only for now
.clk(clk),
.rst(rst),
.wdata(wdata),
.we(we),
.full(full),
.tx(tx)
);
task plusone;
    integer i;
    begin
        for (i = 0; i<7; i = i + 1) begin
            @(posedge clk)#10
            wdata = wdata + 1;
        end
    end
endtask

initial begin
    $dumpvars(0, uart_tb);
    rst = 1;
    #100
    rst = 0;
    wdata = 0;
    #100
    we = 1;
    plusone();
    we = 0;
    #100000;
    $finish;
end

endmodule

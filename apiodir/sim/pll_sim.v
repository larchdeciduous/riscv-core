`timescale 1ns/1ns
// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module pll
(
    input clkin, // 25 MHz, 0 deg
    output clkout0, // 25 MHz, 0 deg
    output clkout1, // 25 MHz, 180 deg
    output reg locked
);

reg r_clkout0, r_clkout1;
assign clkout0 = (locked) ? r_clkout0 : 1'b0;
assign clkout1 = (locked) ? r_clkout1 : 1'b0;
always begin
    #20 r_clkout1 = 1'b1;
    #20 r_clkout1 = 0;
end
always begin
    #2 r_clkout0 = 1'b1;
    #2 r_clkout0 = 0;
end
initial begin
    locked = 0;
    #180
    locked = 1'b1;
end
endmodule

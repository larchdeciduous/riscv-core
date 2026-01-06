synth_top.bit : synth_top.config
	ecppack --compress synth_top.config synth_top.bit
synth_top.config : synth_top.json
	nextpnr-ecp5 --json synth_top.json --textcfg synth_top.config --25k --package CABGA256 --lpf pinout.lpf \
	--parallel-refine --router2-tmg-ripup
synth_top.json : synth.ys
	yosys -s synth.ys -l yosys.log
clean :
	rm synth_top.json synth_top.config synth_top.bit

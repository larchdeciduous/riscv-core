movefile : inst.rom
	cp inst.rom ../../apiodir/inst.rom
inst.rom : firmware.elf
	riscv64-elf-objcopy -O verilog --verilog-data-width=4 firmware.elf inst.rom
firmware.elf : main.c link.ld handler.c start.S
	riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 main.c handler.c start.S -T link.ld -nostdlib -o firmware.elf
clean : 
	rm firmware.elf inst.rom

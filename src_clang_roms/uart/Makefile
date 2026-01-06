movefile : inst.rom
	cp inst.rom ../../apiodir/inst.rom
inst.rom : firmware.elf
	riscv64-elf-objcopy -O verilog --verilog-data-width=2 firmware.elf inst.rom
firmware.elf : main.c link.ld crt0.S
	riscv64-elf-gcc -march=rv32i -mabi=ilp32 *.c *.S -T link.ld -nostdlib -o firmware.elf
clean : 
	rm firmware.elf inst.rom

# crt0.S
.section .text.start
.global _start
_start:
    # Set up stack pointer (use top of SDRAM for now)
    li sp, 0x84000000          # 4MB into SDRAM, adjust as needed

    # Initialize global pointer (if using -mrelax)
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # Clear .bss section
    la a0, __bss_start
    la a1, __bss_end
bss_clear:
    beq a0, a1, bss_done
    sw zero, 0(a0)
    addi a0, a0, 4
    j bss_clear
bss_done:

    # Call main()
    call main

    # Infinite loop if main returns
loop:
    j loop

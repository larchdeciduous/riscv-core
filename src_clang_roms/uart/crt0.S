.section .text.start
.global _start
_start:
    /* Explicitly set stack pointer to top of 32MB RAM */
    li sp, 0x80001000

    /* Set global pointer (prevents relaxation issues) */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* Clear .bss section */
    la a0, __bss_start
    la a1, __bss_end
bss_clear_loop:
    bgeu a0, a1, bss_clear_done
    sw zero, 0(a0)
    addi a0, a0, 4
    j bss_clear_loop
bss_clear_done:

    /* Jump to main */
    call main

    /* Infinite loop if main returns */
infinite_loop:
    j infinite_loop

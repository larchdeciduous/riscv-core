// start.S
// Sets up RAM, drops to User mode, jumps to main()

    .section .text.entry
    .globl _start
    .type  _start, @function

_start:
    // 1. Set stack pointer to top of RAM (defined in linker script)
    la   sp, __stack_top
    // Optional: ensure 16-byte alignment (ABI requirement)
    andi sp, sp, -16

    // 2. Copy .data section from ROM to RAM
    la   t0, __data_load_start   // source (in ROM)
    la   t1, __data_start        // destination (in RAM)
    la   t2, __data_end
    bgeu t1, t2, .L_data_done

.L_copy_data:
    lw   t3, 0(t0)
    sw   t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    bltu t1, t2, .L_copy_data

.L_data_done:

    // 3. Zero .bss section
    la   t1, __bss_start
    la   t2, __bss_end
    bgeu t1, t2, .L_bss_done

.L_zero_bss:
    sw   zero, 0(t1)
    addi t1, t1, 4
    bltu t1, t2, .L_zero_bss

.L_bss_done:

    // 4. Set machine trap vector (direct mode)
    la   t0, machine_handler
    csrw mtvec, t0

    // 5. Set return address for mret → main()
    la   t0, main
    csrw mepc, t0

    // 6. Set previous privilege mode to User (MPP = 00)
    li   t0, 0b11 << 11          // mask for MPP bits
    csrc mstatus, t0             // clear MPP → becomes 00 (U-mode)

    // 7. Drop to User mode and jump to main()
    mret

    // Should never reach here
.L_infinite:
    wfi
    j .L_infinite

    .size _start, . - _start

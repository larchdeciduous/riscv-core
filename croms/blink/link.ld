OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Optional: prevents PHDR errors on some toolchains */
PHDRS { }

MEMORY
{
    rom  (rx) : ORIGIN = 0x00000000, LENGTH = 4K          /* Instruction ROM */
    ram (rwx) : ORIGIN = 0x80000000, LENGTH = 32M         /* 32 MB SDRAM */
}

SECTIONS
{
    .text : {
        *(.text.start)      /* Ensure _start is first */
        *(.text*)
    } > rom

    .rodata : { *(.rodata*) } > rom

    .data : {
        __global_pointer$ = . + 0x800;   /* For linker relaxation */
        *(.sdata .srodata*)
        *(.data*)
    } > ram AT > rom

    __data_lma = LOADADDR(.data);

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > ram

    /* Stack grows downward from the very top of 32MB RAM */
    __stack_top = 0x81000000;
}

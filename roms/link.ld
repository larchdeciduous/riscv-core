OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    rom  (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    ram (rwx) : ORIGIN = 0x80000000, LENGTH = 32M   /* adjust to your SDRAM size */
}

SECTIONS
{
    .text : {
        *(.text.start)          /* crt0 first */
        *(.text*)
    } > rom

    .rodata : { *(.rodata*) } > rom

    .data : {
        __global_pointer$ = . + 0x800;
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

    /* Stack at top of RAM */
    __stack_top = ORIGIN(ram) + LENGTH(ram);
}

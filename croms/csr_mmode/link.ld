ENTRY(_start)

MEMORY
{
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    ram (rwx) : ORIGIN = 0x80000000, LENGTH = 32M
}

SECTIONS
{
    /* 1. Code and read-only data in ROM */
    .text : {
        KEEP(*(.text.entry))      /* _start first */
        *(.text*)
        *(.rodata*)
    } > rom

    /* 2. Initialized data — copied from ROM to RAM */
    .data : {
        __data_start = .;
        *(.data*)
        __data_end = .;
    } > ram AT > rom

    /* 3. Zero-initialized data — in RAM */
    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > ram

    /* 4. Stack — at the VERY END of RAM (grows downward) */
    .stack (NOLOAD) :
    {
        . = ALIGN(16);                       /* ABI requires 16-byte alignment */
        . = ORIGIN(ram) + LENGTH(ram);       
        __stack_top = .;                     /* Stack starts here and grows down */
    } > ram

    /* Discard anything else */
    /DISCARD/ : { *(*) }
}

__data_load_start = LOADADDR(.data);

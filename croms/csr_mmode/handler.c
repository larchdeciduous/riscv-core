// handler.c
#define LED_ADDR 0x20000000U
volatile unsigned int * const leds = (unsigned int *)LED_ADDR;

void machine_handler(void) {
    // Toggle lower 3 bits of LED register
    unsigned int val = *leds;
    val ^= 0x7;           // Flip bits 0,1,2
    *leds = val;

    // Advance mepc past the ecall instruction
    asm volatile (
        "csrr t0, mepc\n\t"
        "addi t0, t0, 4\n\t"
        "csrw mepc, t0"
    );

    // Return to User mode
    asm volatile ("mret");
}

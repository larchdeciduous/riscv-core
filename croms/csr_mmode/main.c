// main.c
int main(void) {
    while (1) {
        // Visible delay (adjust for your clock frequency)
        // ~100,000 iterations gives a noticeable blink on typical 10-100 MHz cores
        for (volatile unsigned int i = 0; i < 5; i++) {
            // Empty loop
        }

        // Request M-mode to toggle LEDs
        asm volatile ("ecall");
    }

    return 0;  // never reached
}

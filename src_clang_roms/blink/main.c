// main.c - Minimal LED blink
#define LED_ADDR ((volatile unsigned int*)0x10000000)

void delay(volatile int cycles) {
    while (cycles--) {}
}

int main() {
    while (1) {
        *LED_ADDR = 0x7;        // Turn on all 3 LEDs
        delay(1000000);
        *LED_ADDR = 0x0;        // Turn off
        delay(1000000);
    }
    return 0;
}

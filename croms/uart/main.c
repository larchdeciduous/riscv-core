// main.c - Minimal LED blink
#define LED_ADDR ((volatile unsigned int*)0x20000000)

void uart_print(const char *str);

void delay(volatile int cycles) {
    while (cycles--) {}
}

int main() {
    while (1) {
        *LED_ADDR = 0x7;        // Turn on all 3 LEDs
        uart_print(u8"hello world\n");
        delay(4000000);
        *LED_ADDR = 0x0;        // Turn off
        uart_print(u8"hello world\n");
        delay(4000000);
    }
    return 0;
}

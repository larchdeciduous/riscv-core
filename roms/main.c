// main.c
#define LED_ADDR ((volatile unsigned int*)0x10000000)

void delay(int cycles) {
    volatile int i;
    for (i = 0; i < cycles; i++);
}

int main() {
    while (1) {
        *LED_ADDR = 0x7;        // all 3 LEDs on
        delay(500000);
        *LED_ADDR = 0x0;        // off
        delay(500000);
    }
    return 0;
}

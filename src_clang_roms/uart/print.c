#include <stdint.h>

#define UART_TX_ADDR 0x20002000UL

static inline void uart_putc(char c)
{
    volatile uint32_t *uart_tx = (volatile uint32_t *)UART_TX_ADDR;

    if (c == '\n') { // write '\r' firest before write '\n'
        *uart_tx = '\r';
    }

    *uart_tx = (uint32_t)(unsigned char)c;
}

void uart_print(const char *str)
{
    while (*str) {
        uart_putc(*str++);
    }
}

void uart_println(const char *str)
{
    uart_print(str);
    uart_putc('\n');
}

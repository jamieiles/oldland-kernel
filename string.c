#include "uart.h"

void putstr(const char *str)
{
	while (*str) {
		const char *p = str++;

		uart_putc(*p);
		if (*p == '\n')
			uart_putc('\r');
	}
}

int strcmp(const char *a, const char *b)
{
	while (*a && *b) {
		if (*a != *b)
			return *a - *b;
		if (!*a || !*b)
			break;
		++a;
		++b;
	}

	return *a - *b;
}

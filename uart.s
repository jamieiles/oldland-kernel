.include "common.s"

	/*
	 * Print a character.
	 *
	 * $r0: character to output.
	 */
.globl putc
putc:
	push	$r2
	push	$r0

	movhi	$r2, 0x8000
	str32	$r0, [$r2, 0x0]

not_empty:
	ldr32	$r0, [$r2, 0x4]
	and	$r0, $r0, 0x1
	cmp	$r0, 0x1
	bne	not_empty

	pop	$r0
	pop	$r2

	ret

	/*
	 * Read a single character from the UART.  Block until received.
	 *
	 * Return: $r0 - the character read.
	 */
.globl getc
getc:
	push	$r2
	movhi	$r0, 0x8000
wait_for_char:
	ldr32	$r2, [$r0, 0x4]
	and	$r2, $r2, 0x2
	cmp	$r2, 0x2
	bne	wait_for_char

	ldr32	$r0, [$r0, 0x0]

	pop	$r2
	ret

.globl drain_uart_rx
drain_uart_rx:
	push	$r2
	movhi	$r0, 0x8000
1:
	ldr32	$r2, [$r0, 0x4]
	and	$r2, $r2, 0x2
	cmp	$r2, 0x2
	bne	empty

	ldr32	$r0, [$r0, 0x0]
	b	1b

empty:
	pop	$r2
	ret

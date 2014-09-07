.include "common.s"

	/* Write a 32 bit integer to the UART, source passed in $r0. */
.globl put_u32
put_u32:
	/* Push caller save registers. */
	push	$r1
	push	$lr

	/* MSB first. */
	or	$r1, $r0, $r0
	lsr	$r1, $r1, 24
	and	$r1, $r1, 0xff
	call	put_u8

	or	$r1, $r0, $r0
	lsr	$r1, $r1, 16
	and	$r1, $r1, 0xff
	call	put_u8

	or	$r1, $r0, $r0
	lsr	$r1, $r1, 8
	and	$r1, $r1, 0xff
	call	put_u8

	or	$r1, $r0, $r0
	and	$r1, $r1, 0xff
	call	put_u8

	/* Pop caller save registers. */
	pop	$lr
	pop	$r1

	ret

put_u8:
	push	$r1
	push	$r2
	push	$r3
	push	$r4
	push	$lr

	and	$r2, $r1, 0x0f
	and	$r1, $r1, 0xf0
	lsr	$r1, $r1, 4

	movhi	$r3, %hi(hex_table)
	orlo	$r3, $r3, %lo(hex_table)

	add	$r4, $r3, $r1
	ldr8	$r4, [$r4, 0]
	call	putc

	add	$r4, $r3, $r2
	ldr8	$r4, [$r4, 0]
	call	putc

	pop	$lr
	pop	$r4
	pop	$r3
	pop	$r2
	pop	$r1

	ret

	.pushsection ".rodata"
hex_table:
	.asciz "0123456789abcdef"
	.popsection

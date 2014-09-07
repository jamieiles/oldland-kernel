.include "common.s"

	/*
	 * Print a string, pointer in $r0.
	 *
	 * $r0: the string to print.
	 * Clobbers $r0.
	 */
.globl putstr
putstr:
	push	$r0
	push	$r2
	push	$r4
	push	$lr

	or	$r2, $r0, $r0
1:
	ldr8	$r0, [$r2, 0]
	and	$r0, $r0, 0xff
	cmp	$r0, 0
	beq	2f
	call	putc
	cmp	$r0, 0xa /* newline. */
	bne	normal_char
	xor	$r0, $r0, $r0
	add	$r0, $r0, 0xd /* line feed */
	call	putc

normal_char:
	add	$r2, $r2, 1
	b	1b

2:
	pop	$lr
	pop	$r4
	pop	$r2
	pop	$r0

	ret

	/*
	 * Like putstr(), but with a trailing newline.
	 */
.global putstrn
putstrn:
	push	$lr
	call putstr

	xor	$r0, $r0, $r0
	add	$r0, $r0, 0xa /* newline */
	call	putc

	xor	$r0, $r0, $r0
	add	$r0, $r0, 0xd /* line feed */
	call	putc

	pop	$lr
	ret

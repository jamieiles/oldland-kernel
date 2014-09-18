.include "common.s"

	/*
	 * clear a range of memory
	 *
	 * $r0: address of memory to clear
	 * $r1: number of bytes to clear
	 */
        .globl bzero
bzero:
	push5	$lr, $r0, $r1, $r2, $r3
	add	$r2, $r0, $r1
	xor	$r3, $r3, $r3
1:
	cmp	$r0, $r2
	beq	2f
	str8	$r3, [$r0, 0]
	add	$r0, $r0, 1
	b	1b

2:
	pop5	$lr, $r0, $r1, $r2, $r3
	ret


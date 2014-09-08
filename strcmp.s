.include "common.s"

	/*
	 * Compare two NUL terminated strings.
	 *
	 * $r1: s1
	 * $r2: s2
	 * return: $r0 - 0 if equal, non-zero otherwise.
	 */
.globl strcmp
strcmp:
	push	$r4
	push	$r3
	push	$r2
	push	$r1

1:
	ldr8	$r3, [$r1, 0]
	ldr8	$r4, [$r2, 0]
	sub	$r0, $r3, $r4
	cmp	$r0, 0
	bne	done

	/* NUL termination. */
	cmp	$r3, 0
	beq	done

	add	$r1, $r1, 1
	add	$r2, $r2, 1
	b	1b

done:
	pop	$r1
	pop	$r2
	pop	$r3
	pop	$r4
	ret

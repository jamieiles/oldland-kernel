.macro	push	reg
	str32	\reg, [$sp, 0]
	sub	$sp, $sp, 4
.endm

.macro	pop	reg
	add	$sp, $sp, 4
	ldr32	\reg, [$sp, 0]
.endm

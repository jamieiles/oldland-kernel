.include "common.s"

	.align	4
	.section ".text"
.globl _start
_start:
	call	sdram_init
	call	setup_stack
	call	output_banner
	call	run_shell

setup_stack:
	/* Top of SRAM. */
	movhi	$sp, 0x0000
	orlo	$sp, $sp, 0x0ffc

	ret

output_banner:
	push	$lr

	movhi	$r0, %hi(header)
	orlo	$r0, $r0, %lo(header)
	call	putstr

	pop	$lr
	ret

	.section ".rodata"
header:
	.asciz "\n\nOldland CPU Kernel\n\n"

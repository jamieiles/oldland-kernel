.include "common.s"

	.align	4
	.section ".text"
.globl _start
_start:
	movhi	$r0, %hi(ex_table)
	orlo	$r0, $r0, %lo(ex_table)
	scr	0, $r0

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

	.pushsection ".rodata"
header:
	.asciz "\n\nOldland CPU Kernel\n\n"
	.popsection

	.balign	64
ex_table:
reset:
	b	reset
illegal_instr:
	b	illegal_instr
swi:
	b	swi
irq:
	b	irq
ifetch_abort:
	b	ifetch_abort	
data_abort:
	b	data_abort

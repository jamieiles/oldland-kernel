.include "common.s"

	.align	4
	.section ".text"
.globl _start
_start:
	call	sdram_init
	call	setup_stack
	call	report_build
	call	run_shell

setup_stack:
	/* Top of SRAM. */
	movhi	$sp, 0x0000
	orlo	$sp, $sp, 0x0ffc

	ret

print_prompt:
	push	$lr

	movhi	$r0, %hi(prompt)
	orlo	$r0, $r0, %lo(prompt)
	call	putstr

	pop	$lr
	ret

report_build:
	push	$lr

	movhi	$r0, %hi(header)
	orlo	$r0, $r0, %lo(header)
	call	putstr

	movhi	$r7, 0x1000
	orlo	$r7, $r7, 0x0000

	movhi	$r0, %hi(buildid_prefix)
	orlo	$r0, $r0, %lo(buildid_prefix)
	call	putstr
	ldr32	$r0, [$r7, 0x4]
	add	$r0, $r0, $r7
	call	putstrn

	movhi	$r0, %hi(builddate_prefix)
	orlo	$r0, $r0, %lo(builddate_prefix)
	call	putstr
	ldr32	$r0, [$r7, 0x8]
	add	$r0, $r0, $r7
	call	putstrn

	pop	$lr
	ret

	/*
	 * Shell commands:
	 *  - cpuid: dump cpuid registers
	 *  - reset: jump to reset vector
	 *  - irqs: list fired irqs
	 *  - sdramtest: perform a short sdram test.
	 */
end:
	b	end

run_shell:
	call	drain_uart_rx
1:
	call	print_prompt
	call	read_command
	b	1b
	/* Never returns. */

	/*
	 * Read a command from the UART.  The command will be NUL terminated
	 * and returned in $r0.
	 *
	 * Command buffer is 128 chars.
	 */
read_command:
	push	$lr
	push	$r7
	push	$r8

	/*
	 * r7: number of characters read.
	 * r8: current character pointer.
	 */
	xor	$r7, $r7, $r7
	movhi	$r0, %hi(cmd_buf)
	orlo	$r0, $r0, %lo(cmd_buf)
	or	$r8, $r0, $r0

next_char:
	cmp	$r7, 128
	beq	terminate
	call	getc
	cmp	$r0, 0x8 /* backspace. */
	beq	delete_char

	str8	$r0, [$r8, 0]
	add	$r8, $r8, 1
	add	$r7, $r7, 1

	cmp	$r0, 0xd /* newline. */
	beq	terminate

	call	putc
	b	next_char

terminate:
	xor	$r0, $r0, $r0
	str8	$r0, [$r8, 0]

	movhi	$r0, %hi(cmd_buf)
	orlo	$r0, $r0, %lo(cmd_buf)

	pop	$r8
	pop	$r7
	pop	$lr
	ret

delete_char:
	cmp	$r7, 0
	beq	next_char

	/* Move back one char. */
	call	putc
	/* Clear the character with a space. */
	xor	$r0, $r0, $r0
	or	$r0, $r0, 0x20
	call	putc
	/* Move the cursor back again. */
	xor	$r0, $r0, $r0
	or	$r0, $r0, 0x8
	call	putc

	sub	$r7, $r7, 1
	sub	$r8, $r8, 1

	b	next_char
	

	.section ".data"
cmd_buf:
	.space	128

	.section ".rodata"
header:
	.asciz "\nOldland CPU\n"
prompt:
	.asciz "\noldland> "
buildid_prefix:
	.asciz "BuildID:\t"
builddate_prefix:
	.asciz "Build Date:\t"

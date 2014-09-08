.include "shelldefs.s"
.include "common.s"

.globl run_shell
run_shell:
	call	drain_uart_rx
1:
	call	print_prompt
	call	read_command
	push	$r0
	call	print_newline
	pop	$r0
	call	run_command
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

	cmp	$r0, 0xd /* newline. */
	beq	terminate
	add	$r8, $r8, 1
	add	$r7, $r7, 1

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
	
run_command:
	push	$lr
	push	$r4
	push	$r5

	movhi	$r4, %hi(shell_cmds_start)
	orlo	$r4, $r4, %lo(shell_cmds_start)
	movhi	$r5, %hi(shell_cmds_end)
	orlo	$r5, $r4, %lo(shell_cmds_end)

1:
	cmp	$r4, $r5
	beq	cmd_not_found

	push	$r0
	and	$r1, $r0, $r0
	ldr32	$r2, [$r4, 0]
	call	strcmp
	cmp	$r0, 0
	beq	cmd_found
	pop	$r0

	/* string compare of commands. */
	add	$r4, $r4, 8
	b	1b

cmd_not_found:
	movhi	$r0, %hi(cmd_not_found_error)
	orlo	$r0, $r0, %lo(cmd_not_found_error)
	call	putstrn
	b	run_command_exit

cmd_found:
	pop	$r0
	ldr32	$r4, [$r4, 0x4]
	call	$r4

run_command_exit:
	pop	$r2
	pop	$r1
	pop	$lr
	ret

print_newline:
	push	$lr
	push	$r0

	xor	$r0, $r0, $r0
	add	$r0, $r0, 0xa
	call	putc

	xor	$r0, $r0, $r0
	add	$r0, $r0, 0xd
	call	putc

	pop	$r0
	pop	$lr
	ret

print_prompt:
	push	$lr

	movhi	$r0, %hi(prompt)
	orlo	$r0, $r0, %lo(prompt)
	call	putstr

	pop	$lr
	ret

	.section ".data"
cmd_buf:
	.space	128

	.section ".rodata"
prompt:
	.asciz "oldland> "
cmd_not_found_error:
	.asciz "Invalid command"

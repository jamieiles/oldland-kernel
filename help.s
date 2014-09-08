.include "shelldefs.s"
.include "common.s"

help_handler:
	push	$lr
	push	$r4
	push	$r3

	movhi	$r0, %hi(help_string)
	orlo	$r0, $r0, %lo(help_string)
	call	putstrn

	movhi	$r3, %hi(shell_cmds_start)
	orlo	$r3, $r3, %lo(shell_cmds_start)
	movhi	$r4, %hi(shell_cmds_end)
	orlo	$r4, $r4, %lo(shell_cmds_end)

1:
	cmp	$r3, $r4
	beq	out

	ldr32	$r0, [$r3, 0]
	call	putstrn

	add	$r3, $r3, 8
	b	1b

out:
	pop	$r3
	pop	$r4
	pop	$lr
	ret

	.pushsection ".rodata"
help_name:	.asciz "help"
	.popsection

SHELL_CMD	help_name, help_handler

	.section ".rodata"
help_string:
	.asciz "Valid commands:"

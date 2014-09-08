.include "shelldefs.s"
.include "common.s"

buildid_handler:
	push	$lr
	push	$r7

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

	pop	$r7
	pop	$lr
	ret

	.pushsection ".rodata"
buildid_name:	.asciz "buildid"
	.popsection

SHELL_CMD	buildid_name, buildid_handler

	.section ".rodata"
buildid_prefix:
	.asciz "BuildID:\t"
builddate_prefix:
	.asciz "Build Date:\t"

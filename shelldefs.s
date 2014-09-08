.macro SHELL_CMD	name, handler
	.pushsection ".shellcmds", "a"
	.align	2
	.long	\name
	.long	\handler
	.popsection
.endm

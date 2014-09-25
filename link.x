OUTPUT_FORMAT("elf32-oldland")
OUTPUT_ARCH(oldland)
ENTRY(_start)
GROUP(libgcc.a)

MEMORY {
	rom : ORIGIN = 0x00000000, LENGTH = 4K
	sdram : ORIGIN = 0x20000000, LENGTH = 32M
}

SECTIONS {
	.text.sdram : {
		*.text.sdram;
	} > sdram

	.bss : {
		*.bss;
	} > sdram

	.rodata.sdram : {
		*.rodata.sdram;
	} > sdram

	.data : {
		*.data;
	} > sdram

	.shellcmds : {
		shell_cmds_start = . ;
		*(.shellcmds);
		shell_cmds_end = . ;
	} > sdram

	.text	: {
		*.text;
	} > sdram

	.rodata	: {
		*(.rodata);
		*(.rodata.*);
		. = ALIGN(4);
	} > sdram
}

OUTPUT_FORMAT("elf32-oldland")
OUTPUT_ARCH(oldland)
ENTRY(_start)
GROUP(libgcc.a)

PHDRS {
	headers PT_PHDR FILEHDR PHDRS ;
	text PT_LOAD ;
	data PT_LOAD ;
}

SECTIONS {
	.text 0x20000000 : AT(0x20000000) {
		*.text;
	} :text

	.rodata	: {
		*(.rodata);
		*(.rodata.*);
		. = ALIGN(4);
	} :data

	.bss : {
		__bss_start = . ;
		*.bss;
		*(COMMON);
		__bss_end = . ;
	}

	.data : {
		*.data;
	}

	.shellcmds : {
		shell_cmds_start = . ;
		*(.shellcmds);
		shell_cmds_end = . ;
	}

	/DISCARD/ : {
		*(.comment);
		*(.debug*);
	}
}

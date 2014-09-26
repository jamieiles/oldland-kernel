#ifndef __SHELL_H__
#define __SHELL_H__

struct shellcmd {
	const char *name;
	void (*handler)(const char *buf);
};

#define DEFINE_SHELL_COMMAND(cmdname, cmdhandler) \
	static struct shellcmd shell_##cmdname __attribute__((section(".shellcmds"))) __used = { \
		.name = #cmdname, \
		.handler = cmdhandler \
	}

void run_shell(void);

#endif /* __SHELL_H__ */

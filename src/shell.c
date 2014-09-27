#include "common.h"
#include "printk.h"
#include "shell.h"
#include "string.h"
#include "uart.h"

static char cmdbuf[128];

static void delete_char(void)
{
	putstr("\x08 \x08");
}

static void read_command(void)
{
	int nchars = 0;

	cmdbuf[0] = '\0';

	for (;;) {
		if (nchars == sizeof(cmdbuf) - 1)
			break;

		cmdbuf[nchars] = uart_getc();

		/* backspace. */
		if (cmdbuf[nchars] == 0x8) {
			if (nchars >= 1) {
				delete_char();
				--nchars;
			}
			continue;
		}

		if (cmdbuf[nchars] == '\r')
			break;

		uart_putc(cmdbuf[nchars++]);
	}

	cmdbuf[nchars] = '\0';
}

static const struct shellcmd *find_command(void)
{
	extern struct shellcmd shell_cmds_start, shell_cmds_end;
	const struct shellcmd *sc;

	for (sc = &shell_cmds_start; sc != &shell_cmds_end; ++sc) {
		if (!strcmp(sc->name, cmdbuf))
			return sc;
	}

	return NULL;
}

static void do_command(void)
{
	const struct shellcmd *sc = find_command();

	if (sc)
		sc->handler(cmdbuf);
	else
		putstr("error: bad command\n");
}

static void process_one_command(void)
{
	read_command();
	putstr("\n");

	if (strcmp("", cmdbuf))
		do_command();
}

void run_shell(void)
{
	for (;;) {
		putstr("> ");
		process_one_command();
	}
}

static void help_handler(const char *buf)
{
	extern struct shellcmd shell_cmds_start, shell_cmds_end;
	const struct shellcmd *sc;

	(void)buf;

	putstr("valid commands:\n");

	for (sc = &shell_cmds_start; sc != &shell_cmds_end; ++sc)
		printk("- %s\n", sc->name);
}
DEFINE_SHELL_COMMAND(help, help_handler);

#include "common.h"
#include "shell.h"
#include "printk.h"

static void reset_handler(const char *buf)
{
	printk("resetting...\n");

	asm volatile("b		%0" :: "r"(0x10000000));
}
DEFINE_SHELL_COMMAND(reset, reset_handler);

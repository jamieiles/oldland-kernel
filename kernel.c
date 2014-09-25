#include "shell.h"
#include "string.h"
#include "uart.h"
#include "printk.h"

void data_abort_handler(unsigned long faultpc, unsigned long faultaddr)
{
	printk("data abort PC=%08x, fault address=%08x\n",
	       faultpc - 8, faultaddr);

	for (;;)
		continue;
}

static void output_banner(void)
{
	printk("%s", "\n\nOldland CPU Kernel\n\n");
}

void root(void)
{
	output_banner();
	run_shell();
}

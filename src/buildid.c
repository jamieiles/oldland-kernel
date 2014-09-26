#include "common.h"
#include "printk.h"
#include "shell.h"
#include "string.h"

#define BOOTROM_ADDR	0x10000000
#define BUILDID_OFFS	0x4
#define BUILDDATE_OFFS	0x8

static void buildid_handler(const char *buf)
{
	const unsigned *bootrom = (const unsigned *)BOOTROM_ADDR;
	const char *buildid = (const char *)(BOOTROM_ADDR + bootrom[1]);
	const char *date = (const char *)(BOOTROM_ADDR + bootrom[2]);

	printk("BuildID:\t%s\n", buildid);
	printk("Build Date:\t%s\n", date);
}
DEFINE_SHELL_COMMAND(buildid, buildid_handler);

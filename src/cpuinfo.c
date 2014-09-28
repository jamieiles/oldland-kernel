#include "common.h"
#include "shell.h"
#include "string.h"
#include "printk.h"

#define read_cpuid(reg) \
({ \
	unsigned long v; \
	asm volatile("cpuid	%0, %1" : "=r"(v) : "I"(reg)); \
	v; \
})

static void report_version(unsigned long cpuid)
{
	unsigned short vendor, model;

	vendor = (cpuid >> 16) & 0xffff;
	model = cpuid & 0xffff;

	printk("Vendor:       %04x\n", vendor);
	printk("Model:        %04x\n", model);
}

static void report_clock(unsigned long cpuid)
{
	printk("Clock:        %u\n", cpuid);
}

static void report_cache(const char *pfx, unsigned long cpuid)
{
	unsigned num_words = cpuid & 0xff;
	unsigned num_lines = (cpuid >> 8) & 0xffff;

	printk("%s Line Size: %u\n", pfx, num_words * 4);
	printk("%s Size:      %u\n", pfx, num_lines * num_words * 4);
}

static void cpuinfo_handler(const char *buf)
{
	report_version(read_cpuid(0));
	report_clock(read_cpuid(1));
	report_cache("I$", read_cpuid(3));
	report_cache("D$", read_cpuid(4));
}
DEFINE_SHELL_COMMAND(cpuinfo, cpuinfo_handler);

#include "common.h"
#include "shell.h"
#include "string.h"
#include "printk.h"

#define SD_CLK_DIVIDER	1
#define SD_NCR		8
#define SD_CS		1

#define SPI_CTRL_REG		0x0
#define SPI_CS_ENABLE_REG	0x1
#define SPI_XFER_CTRL_REG	0x2
#define SPI_XFER_BUF_OFFS	8192
#define SPI_BASE_ADDRESS	0x80004000

#define XFER_START		(1 << 16)
#define XFER_BUSY		(1 << 17)

#define DATA_START_TOKEN	0xfe
#define BLOCK_SIZE		512

static volatile unsigned char *spi_cmd_buf =
	(volatile unsigned char *)(SPI_BASE_ADDRESS + SPI_XFER_BUF_OFFS);

struct spi_cmd {
	unsigned char cmd;
	unsigned char arg[4];
	unsigned char crc;

	const unsigned char *data;
	size_t tx_datalen;
	size_t rx_datalen;
};

struct r1_response {
	unsigned char v;
};

#define R1_ERROR_MASK 0xfe

static void spi_write_reg(unsigned int regnum, unsigned long val)
{
	volatile unsigned long *base = (volatile unsigned long *)SPI_BASE_ADDRESS;

	base[regnum] = val;
}

static unsigned long spi_read_reg(unsigned int regnum)
{
	volatile unsigned long *base = (volatile unsigned long *)SPI_BASE_ADDRESS;

	return base[regnum];
}

static void spi_wait_idle(void)
{
	unsigned long xfer_ctrl;

	do {
		xfer_ctrl = spi_read_reg(SPI_XFER_CTRL_REG);
	} while (xfer_ctrl & XFER_BUSY);
}

static void send_initial_clock(void)
{
	spi_write_reg(SPI_CTRL_REG, SD_CLK_DIVIDER);
	spi_write_reg(SPI_CS_ENABLE_REG, 0);
	spi_write_reg(SPI_XFER_CTRL_REG, XFER_START | (80 / 10));
	spi_wait_idle();
}

static void spi_do_command(const struct spi_cmd *cmd)
{
	size_t m, cmdlen;

	cmdlen = sizeof(cmd->cmd) + cmd->tx_datalen + cmd->rx_datalen + SD_NCR;

	/* The command. */
	spi_cmd_buf[0] = cmd->cmd;
	for (m = 0; m < 4; ++m)
		spi_cmd_buf[1 + m] = cmd->arg[m];
	spi_cmd_buf[5] = cmd->crc;
	/* Transmit data. */
	for (m = 0; m < cmd->tx_datalen; ++m)
		spi_cmd_buf[6 + m] = cmd->data[m];
	/* Initialize receive buffer so we don't shift out new, garbage data. */
	for (m = 6 + cmd->tx_datalen; m < cmdlen; ++m)
		spi_cmd_buf[m] = 0;

	spi_write_reg(SPI_CS_ENABLE_REG, SD_CS);
	spi_write_reg(SPI_XFER_CTRL_REG, XFER_START | cmdlen);
	spi_wait_idle();
}

static const volatile unsigned char *find_r1_response(struct r1_response *r1)
{
	const volatile unsigned char *p = spi_cmd_buf + 6;

	while (*p == 0xff)
		++p;

	r1->v = *p;

	return p;
}

static int send_reset(void)
{
	struct spi_cmd cmd = {
		.cmd = 0x40,
		.crc = 0x95,
		.rx_datalen = 1,
	};
	struct r1_response r1;

	spi_do_command(&cmd);
	find_r1_response(&r1);

	return r1.v & R1_ERROR_MASK;
}

static int send_if_cond(void)
{
	struct spi_cmd cmd = {
		.cmd = 0x48,
		.crc = 0x87,
		.arg = { 0x00, 0x00, 0x01, 0xaa },
		.rx_datalen = 1,
	};
	struct r1_response r1;

	spi_do_command(&cmd);
	find_r1_response(&r1);

	return r1.v & R1_ERROR_MASK;
}

static int send_read_ocr(void)
{
	struct spi_cmd cmd = {
		.cmd = 0x7a,
		.rx_datalen = 5,
	};
	struct r1_response r1;

	spi_do_command(&cmd);
	find_r1_response(&r1);

	return r1.v & R1_ERROR_MASK;
}

static int send_acmd(void)
{
	struct spi_cmd cmd = {
		.cmd = 0x77,
		.arg = { 0x00, 0x00, 0x00, 0x00 },
		.rx_datalen = 1,
	};
	struct r1_response r1;

	spi_do_command(&cmd);
	find_r1_response(&r1);

	return r1.v & R1_ERROR_MASK;
}

static int sd_wait_ready(void)
{
	struct spi_cmd cmd = {
		.cmd = 0x69,
		.arg = { 0x40, 0x00, 0x00, 0x00 },
		.rx_datalen = 1,
	};
	struct r1_response r1;
	int rc = send_acmd();

	if (rc)
		return rc;

	spi_do_command(&cmd);
	find_r1_response(&r1);

	return r1.v & R1_ERROR_MASK;
}

static int sd_set_blocklen(void)
{
	struct spi_cmd cmd = {
		.cmd = 0x50,
		/* BLOCK_SIZE bytes */
		.arg = { 0x00, 0x00, 0x02, 0x00 },
		.rx_datalen = 1,
	};
	struct r1_response r1;

	spi_do_command(&cmd);
	find_r1_response(&r1);

	return r1.v & R1_ERROR_MASK;
}

static const volatile unsigned char *
find_data_start(const volatile unsigned char *r1ptr)
{
	++r1ptr;

	while (*r1ptr != DATA_START_TOKEN)
		++r1ptr;

	return r1ptr + 1;
}

static void copy_block(unsigned char *dst, const volatile unsigned char *src)
{
	unsigned m;

	for (m = 0; m < BLOCK_SIZE; ++m)
		dst[m] = src[m];
}

static int assert_partitioned(const unsigned char *mbr)
{
	if (mbr[0x1fe] != 0x55 && mbr[0x1ff] != 0xaa) {
		printk("ERROR: card not partitioned, no MBR\n");
		return -1;
	}

	return 0;
}

struct partition_entry {
	unsigned char status;
	unsigned char chs_start[3];

	unsigned char type;
	unsigned char chs_end[3];

	union {
		unsigned char first_lba_bytes[4];
		unsigned long first_lba;
	};

	union {
		unsigned char num_sectors_bytes[4];
		unsigned long num_sectors;
	};
};

static void sd_report_partitions(const unsigned char *mbr)
{
	int rc;
	unsigned m;

	rc = assert_partitioned(mbr);
	if (rc)
		return;

	for (m = 0; m < 4; ++m) {
		struct partition_entry pe;

		memcpy(&pe, mbr + 0x1be + (m * sizeof(pe)), sizeof(pe));

		if (pe.status == 0)
			continue;

		printk("%u: 0x%08x %u %s\n", m, pe.first_lba, pe.num_sectors,
		       pe.status ? "(boot)" : "");
	}
}

static void read_mbr(void)
{
	static unsigned char mbr[BLOCK_SIZE];
	struct spi_cmd cmd = {
		.cmd = 0x51,
		/* Block 0. */
		.arg = { 0x00, 0x00, 0x00, 0x00 },
		/* r1, start token, data, CRC16 */
		.rx_datalen = 1 + 1 + BLOCK_SIZE + 2,
	};
	struct r1_response r1;
	const volatile unsigned char *r1ptr, *data_start;

	spi_do_command(&cmd);
	r1ptr = find_r1_response(&r1);
	data_start = find_data_start(r1ptr);
	copy_block(mbr, data_start);

	sd_report_partitions(mbr);
}

static void readmbr_handler(const char *buf)
{
	int rc;

	send_initial_clock();
	rc = send_reset();
	if (rc) {
		printk("readmbr: failed to reset\n");
		return;
	}
	rc = send_if_cond();
	if (rc) {
		printk("readmbr: failed to send interface conditions\n");
		return;
	}
	rc = send_read_ocr();
	if (rc) {
		printk("readmbr: failed to read OCR\n");
		return;
	}
	rc = sd_wait_ready();
	if (rc) {
		printk("readmbr: failed to wait for SD to become ready\n");
		return;
	}
	rc = sd_set_blocklen();
	if (rc) {
		printk("readmbr: failed to set blocklen\n");
		return;
	}

	read_mbr();
}
DEFINE_SHELL_COMMAND(readmbr, readmbr_handler);

.include "shelldefs.s"
.include "common.s"

.equ SD_CLK_DIVIDER, 1
/* Responses can take up to 8 bytes where MOSI is held high. */
.equ SD_NCR, 8
.equ SD_CS, 1

.equ CONTROL_REG_OFFS, 0x0
.equ CS_ENABLE_REG_OFFS, 0x4
.equ XFER_CONTROL_REG_OFFS, 0x8
.equ SPI_MASTER_ADDRESS, 0x80004000

/* r1 response, start token, data, CRC16 */
.equ BLOCK_READ_CMD_LEN, (6 + 1 + 1 + 512 + 2 + SD_NCR)

spi_wait_idle:
	push3	$lr, $r1, $r0
1:
	ldr32	$r0, [$r10, XFER_CONTROL_REG_OFFS]
	movhi	$r1, 0x2
	and	$r0, $r0, $r1
	cmp	$r0, $r1
	beq	1b

	pop3	$lr, $r1, $r0
	ret

	/*
	 * Provide the SD card with 80 clock cycles before interacting,  CS is
	 * not asserted during this time.
	 *
	 * $r10: base address of the SPI master.
	 * $r11: base address of the SPI master transmit buffer.
	 */
sd_initial_clock:
	push2	$r0, $lr

	movhi	$r0, 0x0
	orlo	$r0, $r0, SD_CLK_DIVIDER
	str32	$r0, [$r10, CONTROL_REG_OFFS]

	xor	$r0, $r0, $r0
	str32	$r0, [$r10, CS_ENABLE_REG_OFFS]

	/* Start a transfer with 10 bytes == 80 clocks. */
	movhi	$r0, 0x1
	orlo	$r0, $r0, 10
	str32	$r0, [$r10, XFER_CONTROL_REG_OFFS]

	call	spi_wait_idle

	pop2	$r0, $lr
	ret

	/*
	 * Copy the command in $r0 into the SPI master xfer buffer.  Pad with
	 * zeroes to the transmit length.
	 *
	 * $r0: the address of the transmit data.
	 * $r1: the transfer length in bytes.
	 * $r2: the transmit data length length (<= $r1) in bytes.
	 */
copy_command:
	push5	$r11, $r5, $r4, $r0, $lr

	xor	$r4, $r4, $r4
1:
	cmp	$r4, $r1
	beq	copy_done

	cmp	$r4, $r2
	blt	copy_byte

	/* Zero padding. */
	xor	$r5, $r5, $r5
	b	store_byte

	/* Copy transmit byte. */
copy_byte:
	ldr8	$r5, [$r0, 0]
store_byte:
	str8	$r5, [$r11, 0]

	add	$r11, $r11, 1
	add	$r0, $r0, 1
	add	$r4, $r4, 1
	b	1b

copy_done:
	pop5	$r11, $r5, $r4, $r0, $lr
	ret

	/*
	 * Send a command to the SD card.
	 *
	 * $r1: the transfer length in bytes.
	 * $r3: the SD card chip select.
	 */
sd_send_cmd:
	push4	$lr, $r1, $r2, $r4

	str32	$r3, [$r10, CS_ENABLE_REG_OFFS]

	movhi	$r4, 0x1
	or	$r4, $r4, $r1
	str32	$r4, [$r10, XFER_CONTROL_REG_OFFS]

	call	spi_wait_idle

	pop4	$lr, $r1, $r2, $r4
	ret

	/*
	 * Get the address of the r1 response - there can be up to NCR high
	 * cycles.
	 */
sd_get_r1_address:
	push2	$lr, $r11

	/* r1 response is the 7th byte xferred. in-idle-state can be set. */
	add	$r11, $r11, 6
1:
	ldr8	$r0, [$r11, 0]
	cmp	$r0, 0xff
	bne	2f
	add	$r11, $r11, 1
	b	1b
2:
	or	$r0, $r11, $r11
	pop2	$lr, $r11
	ret

.macro load_const_cmd cmd, txlen, xferlen
	movhi	$r0, %hi(\cmd)
	orlo	$r0, $r0, %lo(\cmd)
	ldr32	$r1, \xferlen
	ldr32	$r2, \txlen
	xor	$r3, $r3, $r3
	or	$r3, $r3, SD_CS
	call	copy_command
.endm

abort_if_r1_error:
	push2	$r1, $lr

	call	sd_get_r1_address
	ldr8	$r0, [$r0, 0]
	and	$r1, $r0, 0xfe
	cmp	$r1, 0
	bne	fatal_error

	pop2	$r1, $lr
	ret

sd_send_reset:
	push6	$lr, $r11, $r3, $r2, $r1, $r0

	load_const_cmd cmd0, cmd0txlen, cmd0len
	call	copy_command
	call	sd_send_cmd
	call	abort_if_r1_error
	
	pop6	$lr, $r11, $r3, $r2, $r1, $r0
	ret

sd_send_if_cond:
	push6	$lr, $r11, $r3, $r2, $r1, $r0

	load_const_cmd cmd8, cmd8txlen, cmd8len
	call	copy_command
	call	sd_send_cmd
	call	abort_if_r1_error
	
	pop6	$lr, $r11, $r3, $r2, $r1, $r0
	ret

sd_read_ocr:
	push6	$lr, $r11, $r3, $r2, $r1, $r0

	load_const_cmd cmd58, cmd58txlen, cmd58len
	call	copy_command
	call	sd_send_cmd
	call	abort_if_r1_error
	
	pop6	$lr, $r11, $r3, $r2, $r1, $r0
	ret

sd_wait_ready:
	push6	$lr, $r11, $r3, $r2, $r1, $r0

1:
	push	$r11
	load_const_cmd cmd55, cmd55txlen, cmd55len
	call	copy_command
	call	sd_send_cmd
	call	abort_if_r1_error
	load_const_cmd acmd41, acmd41txlen, acmd41len
	call	copy_command
	call	sd_send_cmd
	call	abort_if_r1_error
	pop	$r11
	and	$r0, $r0, 0x1
	cmp	$r0, 0x1
	beq	1b
	
	pop6	$lr, $r11, $r3, $r2, $r1, $r0
	ret

sd_set_blocklen:
	push6	$lr, $r11, $r3, $r2, $r1, $r0

	load_const_cmd cmd16, cmd16txlen, cmd16len
	call	copy_command
	call	sd_send_cmd
	call	abort_if_r1_error
	
	pop6	$lr, $r11, $r3, $r2, $r1, $r0
	ret

	/*
	 * Read a block from the SD card.
	 *
	 * $r0: the block address.
	 * Returns pointer to data in $r0.
	 */
sd_read_block:
	push4	$lr, $r1, $r2, $r3

	/* Initialize the transmit data. */
	push	$r0
	or	$r0, $r11, $r11
	ldr32	$r1, readmbrcmdlen
	call	bzero
	pop	$r0

	/* Byte swapped sector number. */
	str8	$r0, [$r11, 4]
	lsr	$r0, $r0, 8
	str8	$r0, [$r11, 3]
	lsr	$r0, $r0, 8
	str8	$r0, [$r11, 2]
	lsr	$r0, $r0, 8
	str8	$r0, [$r11, 1]
	/* Command number. */
	xor	$r3, $r3, $r3
	or	$r3, $r3, 0x51
	str8	$r3, [$r11, 0]

	/* Transfer length. */
	movhi	$r1, %hi(BLOCK_READ_CMD_LEN)
	orlo	$r1, $r1, %lo(BLOCK_READ_CMD_LEN)
	/* Chip select. */
	xor	$r3, $r3, $r3
	or	$r3, $r3, SD_CS

	call	sd_send_cmd

	or	$r0, $r11, $r11
1:
	ldr8	$r1, [$r0, 0]
	add	$r0, $r0, 1
	cmp	$r1, 0xfe
	beq	2f
	b	1b

2:
	pop4	$lr, $r1, $r2, $r3
	ret

	.pushsection ".rodata"
unpartitioned_error: .asciz "ERROR: card not partitioned, no MBR"
	.popsection

	.pushsection ".data"
	.align 4
block_buf:	.skip 512, 0
	.popsection

	/*
	 * Output the list of partitions.
	 *
	 * $r0 is the MBR.
	 */
dump_partitions:
	push4	$r3, $r2, $r1, $lr

	/* First partition offset. */
	add	$r2, $r0, 0x1be
	xor	$r3, $r3, $r3
	
1:
	cmp	$r3, 4
	beq	finish_dump

	ldr8	$r1, [$r2, 0x4]
	cmp	$r1, 0
	beq	next_partition

	/* Output partition number. */
	or	$r1, $r3, $r3
	call	put_u8

	/* Output bootable flag. */
	movhi	$r0, %hi(boot_str)
	orlo	$r0, $r0, %lo(boot_str)

	ldr8	$r1, [$r2, 0x0]
	cmp	$r1, 0x80
	beq	output_boot

	movhi	$r0, %hi(not_boot_str)
	orlo	$r0, $r0, %lo(not_boot_str)
output_boot:
	call	putstrn

next_partition:
	add	$r3, $r3, 1
	add	$r2, $r2, 0x10
	b	1b

finish_dump:
	pop4	$r3, $r2, $r1, $lr
	ret

.pushsection ".rodata"
boot_str: .asciz "(boot) "
not_boot_str: .asciz "       "
.popsection

do_read_mbr:
	push6	$lr, $r11, $r3, $r2, $r1, $r0

	xor	$r0, $r0, $r0
	call	sd_read_block

	or	$r1, $r0, $r0
	movhi	$r0, %hi(block_buf)
	orlo	$r0, $r0, %lo(block_buf)
	movhi	$r2, %hi(512)
	orlo	$r2, $r2, %lo(512)
	call	memcpy

	/* Check that there is an MBR. */
	ldr16	$r1, [$r0, 0x1fe]
	movhi	$r2, 0x0
	orlo	$r2, $r2, 0xaa55
	cmp	$r1, $r2
	bne	not_partitioned

	movhi	$r0, %hi(block_buf)
	orlo	$r0, $r0, %lo(block_buf)
	call	dump_partitions

	b	out

not_partitioned:
	movhi	$r0, %hi(unpartitioned_error)
	orlo	$r0, $r0, %lo(unpartitioned_error)
	call	putstrn
out:	
	pop6	$lr, $r11, $r3, $r2, $r1, $r0
	ret

	/*
	 * Command structures.
	 */
	.pushsection ".rodata"
cmd0:		.ascii "\x40\x00\x00\x00\x00\x95"
cmd8:		.ascii "\x48\x00\x00\x01\xaa\x87"
			     /* 512 byte block length. */
cmd16:		.ascii "\x50\x00\x00\x02\x00\x00"
cmd55:		.ascii "\x77\x00\x00\x00\x00\x00"
cmd58:		.ascii "\x7a\x00\x00\x00\x00\x00"
acmd41:		.ascii "\x69\x40\x00\x00\x00\x00"
	.align 2
cmd0txlen:	.long 6
cmd0len:	.long 6 + 1 + SD_NCR
cmd8txlen:	.long 6
cmd8len:	.long 6 + 1 + SD_NCR
cmd16txlen:	.long 6
cmd16len:	.long 6 + 1 + SD_NCR
cmd55txlen:	.long 6
cmd55len:	.long 6 + 1 + SD_NCR
cmd58txlen:	.long 6
cmd58len:	.long 6 + 5 + SD_NCR
acmd41txlen:	.long 6
acmd41len:	.long 6 + 1 + SD_NCR
		/* r1 response, start token, data, CRC16 */
readmbrcmdlen:	.long 6 + 1 + 1 + 512 + 2 + SD_NCR
	.popsection

fatal_error:
	movhi	$r0, %hi(fatal_error_str)
	orlo	$r0, $r0, %lo(fatal_error_str)
	call	putstrn
1:
	b	1b
	.pushsection ".rodata"
fatal_error_str: .asciz "Fatal SD card error"
	.popsection
	
readmbr_handler:
	push3	$lr, $r11, $r10

	movhi	$r10, 0x8000
	orlo	$r10, $r10, 0x4000

	movhi	$r11, 0x8000
	orlo	$r11, $r11, 0x6000

	call	sd_initial_clock
	call	sd_send_reset
	call	sd_send_if_cond
	call	sd_read_ocr
	call	sd_wait_ready
	call	sd_set_blocklen
	call	do_read_mbr

	pop3	$lr, $r11, $r10
	ret

	.pushsection ".rodata"
readmbr_name:	.asciz "readmbr"
	.popsection

SHELL_CMD	readmbr_name, readmbr_handler

|
| scsi.S
|
| SCSI-drive handling (via SCSI manager)
|

	.include "traplist.i"
	.include "structs.i"
	.include "sysglobs.i"

|
| module local constants
|

#define SCSI_WAIT 600	/* Same as in Booter */

|
| module local variables
|

#define ourSCSIID localSCSIID(%a6)
#define ourSCSICommand localSCSICommand(%a6)
#define ourSCSIInstr localSCSIInstr(%a6)
#define ourCompletionStatus localCompletionStatus(%a6)
#define ourCompletionMessage localCompletionMessage(%a6)

localSCSIID:
	.word	0

localSCSICommand:
	.byte	8, 0, 0, 0, 1, 0

localSCSIInstr:
	.word	scInc
	.long	0
	.long	512
	.word	scStop
	.long	0
	.long	0

localCompletionStatus:
	.word	0

localCompletionMessage:
	.word	0

|
| useful functions
|

/*
 * basic sequence for read_sector:
 *
 * SCSIGet
 * SCSISelect
 * SCSICmd
 * SCSIRead
 * SCSIComplete
 *
 * if an error occurs for either SCSICmd or SCSIRead, call SCSIComplete
 *
 * The SCSICmd buffer is 6 bytes:
 * command type: 8 (read)
 * LUN and high 5 bits of address: (addr >> 16) & 0x1f
 * next 8 bits of address: (addr >> 8) & 0xff
 * low 8 bits of address: addr & 0xff
 * number of blocks to transfer: 1
 * flags (ignored): 0
 *
 * This information based on the SCSI access code in booter
 */

	.globl	read_sector
read_sector:
	moveb	%d0, 3 + ourSCSICommand
	asrl	#8, %d0
	moveb	%d0, 2 + ourSCSICommand
	asrl	#8, %d0
	moveb	%d0, 1 + ourSCSICommand

	movel	%a0, scParam1 + ourSCSIInstr

| A "sequence" number (used for diagnosing errors)
	clrw	%sp@-

	subql	#2, %sp
	_SCSIGet
	movew	%sp@+, %d0
	bne	read_sector_error

	movew	%sp@+, %d0
	addq	#1, %d0
	movew	%d0, %sp@-

	subql	#2, %sp
	movew	ourSCSIID, %sp@-
	_SCSISelect
	movew	%sp@+, %d0
	bne	read_sector_error

	movew	%sp@+, %d0
	addq	#1, %d0
	movew	%d0, %sp@-

	subql	#2, %sp
	leal	ourSCSICommand, %a0
	movel	%a0, %sp@-
	movew	#6, %sp@-
	_SCSICmd
	movew	%sp@+, %d0
	bne	read_sector_messy_error

	movew	%sp@+, %d0
	addq	#1, %d0
	movew	%d0, %sp@-

	subql	#2, %sp
	leal	ourSCSIInstr, %a0
	movel	%a0, %sp@-
	_SCSIRead
	movew	%sp@+, %d0
	bne	read_sector_messy_error

	movew	%sp@+, %d0
	addq	#1, %d0
	movew	%d0, %sp@-

read_sector_cleanup:
	subql	#2, %sp
	leal	ourCompletionStatus, %a0
	movel	%a0, %sp@-
	leal	ourCompletionMessage, %a0
	movel	%a0, %sp@-
	movel	#SCSI_WAIT, %sp@-
	_SCSIComplete
	movew	%sp@+, %d0
	bne	read_sector_error

| clean up our "sequence" number
	addql	#2, %sp

	rts

read_sector_messy_error:
	movew	%sp@+, %d1
	bsrs	read_sector_error_print
	movew	#0x0666, %sp@-
	bras	read_sector_cleanup

read_sector_error:
	movew	%sp@+, %d1

read_sector_error_print:
	movew	%d0, %sp@-
	movew	%d1, %sp@-
	pea	%pc@(read_sector_error_message)
	bsr	emit_string
	movew	%sp@+, %d0
	bsr	emit_hex_word
	moveb	#':', %d0
	bsr	emit_char
	moveb	#' ', %d0
	bsr	emit_char
	movew	%sp@+, %d0
	bsr	emit_hex_word
	moveb	#'\n', %d0
	bsr	emit_char
	rts

read_sector_error_message:
	.ascii	"SCSI error reading sectors sequence \0"

|
| EOF
|

|
| parttable.S
|
| Partition Table (map) handling
|

	.include "sysglobs.i"
	.include "structs.i"

|
| module local variables
|

#define ourPartitionTable localPartitionTable(%a6)

localPartitionTable:
	.long	0

|
| useful functions
|

	.globl	parttable_init
parttable_init:
	subl	#512, BufPtr
	movel	BufPtr, %a0
	movel	%a0, ourPartitionTable
	moveql	#1, %d0

parttable_dump_loop:
	movel	%d0, %sp@-
	movel	ourPartitionTable, %a0
	bsr	read_sector

	movel	ourPartitionTable, %a0
	bsr	dump_partition

	movel	%sp@+, %d0
	addql	#1, %d0
	cmpl	%a0@(pmMapBlkCount), %d0
| we want to loop until %d0 is greater than %a0@(pmMapBlkCount)
	blss	parttable_dump_loop

|	movel	ourPartitionTable, %a0
|	bsr	dump_sector

	rts

dump_partition:
	movel	%a0, %sp@-

	leal	%pc@(part_string_1), %a0
	movel	%a0, %sp@-
	bsr	emit_string

	movel	%sp@+, %a0
	movel	%a0@(pmPyPartStart), %d0
	movel	%a0, %sp@-
	bsr	emit_hex_long

	leal	%pc@(part_string_2), %a0
	movel	%a0, %sp@-
	bsr	emit_string

	movel	%sp@+, %a0
	movel	%a0@(pmPartBlkCnt), %d0
	movel	%a0, %sp@-
	bsr	emit_hex_long

	leal	%pc@(part_string_3), %a0
	movel	%a0, %sp@-
	bsr	emit_string

	movel	%sp@+, %a0
	movel	%a0, %sp@-
	addl	#pmPartName, %a0
	movel	#31, %d0
	bsr	emit_limited_string

	leal	%pc@(part_string_4), %a0
	movel	%a0, %sp@-
	bsr	emit_string

	movel	%sp@+, %a0
	movel	%a0, %sp@-
	addl	#pmPartType, %a0
	movel	#31, %d0
	bsr	emit_limited_string

	leal	%pc@(part_string_5), %a0
	movel	%a0, %sp@-
	bsr	emit_string

	movel	%sp@+, %a0
	rts

part_string_1:
	.ascii	"Partition: start = \0"
part_string_2:
	.ascii	", size = \0"
part_string_3:
	.ascii	", name = \"\0"
part_string_4:
	.ascii	"\", type = \"\0"
part_string_5:
	.ascii	"\".\n\0"

|
| EOF
|

#
# test4.s
#
# fourth mac bootsector test
#

	.include "traplist.i"
	.include "sysglobs.i"
	.include "structs.i"

#
# Boot block structure, from IM:Files, Chapter 2/Data Organization on Volumes
# "Boot Blocks". Sample data ripped from some System install disks (not like
# it matters, now does it?), and stripped to the minimum I found usable.
#

#
# Interestingly enough, it appears that only the first, fourth, and fifth
# words are sacred to the ROM startup code. If we _really_ needed the space,
# we could probably place our code starting where the System file name is
# supposed to be stored.
#
# The fifth word may also only be sacred to the original ROMs (see TN DV 03).
#

blockstart:
	.word	0x4c4b		;# boot signature
#	.word	0x6000, 0x0086	;# branch to code start (would be 0x008c for
	bra	start		;# new-format block header)
	.word	0x4418		;# a version code of some sort
	.word	0x0000		;# Secondary sound and video buffer allocation
				;# (should always be 0, see retired TN DV 03)

#
# By now, we've covered all the boot block fields, and are ready to start in
# on some actual code.
#

start:

#
# This test program is to get the Resource Manager initialized, a nessecary
# prerequisite to the Font Manager, which we will need later.
#
# A _SysError (sad mac) of FACE indicates a successful initialization.
#
# This works on my IIcx.
#

#
# First, set up the system heap
#

	moveal	SysZone, %a0
	addal	#0x20000, %a0	;# 256k of heap... Hope it's enough...
	_SetAppBase
	movel	SysZone, TheZone

#
# Next, allocate a block for us to use
#

	movel	#0x8000, %d0
	_NewPtr_Sys_Clear
	tst.w	%d0
	bmi	error

#
# Move to our new location
#

	move.l	%a0, %sp@-
	move.l	%a0, %a1
	lea.l	%pc@(blockstart), %a0
	move.l	#0x400, %d0
	_BlockMove
	move.l	%sp@+, %a0
	jmp	%a0@(new_loc_target)

new_loc_target:

#
# Allocate a block for our stack
#

	movel	#0x4000, %d0
	_NewPtr_Sys_Clear
	tstw	%d0
	bmi	error
	addl	#0x4000, %a0
	movel	%a0, %sp

#
# Hook the File Manager traps (so we can fake out the resourece manager)
#

	lea	%pc@(file_error), %a0
	lea	%pc@(file_traps), %a6
hook_loop:
	movew	(%a6), %d0
	tstw	%d0
	bmis	done_hooks
	_SetTrapAddress_NewOS
	addql	#2, %a6
	bras	hook_loop
done_hooks:

	lea	%pc@(file_read_hook), %a0
	movew	#0x02, %d0
	_SetTrapAddress_NewOS

	lea	%pc@(file_openrf_hook), %a0
	movew	#0x0a, %d0
	_SetTrapAddress_NewOS

	lea	%pc@(file_geteof_hook), %a0
	movew	#0x11, %d0
	_SetTrapAddress_NewOS

#
# Initialize the Resource Manager, now that we have the file manager traps
# replaced.
#

	subql	#2, %sp
	_InitResources
	tst.w	%sp@+
	bmis	error

#
# Signal FACE error, to indicate success.
#
	movw	#0xface, %d0

#
# Our simple error handler
#

error:
	_SysError

#
# Our file manager error traps
#
# These are very simple implementations, intended only to fool the Resource
# Manager. To say that they are easily broken is an understatement.
#

file_error:
#
# The trap manager, at least on the Mac Plus and IIcx, passes the trap word
# in %d1. This is not, as far as I can tell, documented anywhere. All joy
# to the people at Apple for this one...
#
# We use it as a system error code because it's vanishingly unlikely to be
# mistaken for a real error, and indicates which trap to work on next.
#
	movew	%d1, %d0
	_SysError

file_openrf_hook:
	movew	#4, %a0@(ioRefNum)
	movew	#0, %a0@(ioResult)
	movew	#0, %d0
	rts

file_geteof_hook:
	movel	#system_file_end - fake_system_file, %a0@(ioMisc)
	movew	#0, %a0@(ioResult)
	movew	#0, %d0
	rts

file_read_hook:
	cmpiw	#1, %a0@(ioPosMode)	;# error if ioPosMode != fsFromStart
	bnes	file_read_error

	movel	%a0, %sp@-
	leal	%pc@(fake_system_file), %a1
	movel	%a1, %d1
	movel	%a0@(ioReqCount), %d0
	movel	%a0@(ioBuffer), %a1
	movel	%a0@(ioPosOffset), %a0
	addal	%d1, %a0
	_BlockMove
	movel	%sp@+, %a0

	movew	#0, %a0@(ioResult)
	movew	#0, %d0
	rts

file_read_error:
	movw	#0xa002, %d0
	_SysError

file_traps:
	.word	0x00, 0x01,       0x03
	.word	0x04, 0x05, 0x06, 0x07
	.word	0x08, 0x09,       0x0b
	.word	0x0c, 0x0d, 0x0e, 0x0f
	.word	0x10,       0x12, 0x13
	.word	0x14, 0x15, 0x16, 0x17
	.word	0x18, 0x35, 0x41, 0x42
	.word	0x43, 0x44, 0x45, 0x60
	.word	0xffff

#
# Our fake system file (as empty as we can make it)
#

	.balign	0x100
fake_system_file:
	.long	resource_data - fake_system_file;# Offset of resource data
	.long	resource_map - fake_system_file	;# Offset of resource map
	.long	resource_map - resource_data	;# Length of resource data
	.long	system_file_end - resource_map	;# Length of resource map
	.fill	112		;# "Reserved for system use"
	.fill	128		;# Application data (none)
resource_data:
	.long	0		;# the one resource we have, length 0
resource_map:
	.fill	16		;# reserved for copy of resource header
	.long	0		;# Handle to next resource map
	.word	0		;# File reference number
	.word	0		;# Resource file attributes
	.word	type_list - resource_map
	.word	name_list - resource_map
type_list:
	.word	0		;# Number of resource types - 1
	.long	0x4e796566	;# Resource type
	.word	0		;# Number of resources of this type - 1
	.word	reference_list - type_list

reference_list:
	.word	0		;# Resource ID
	.word	0xffff		;# Offset from name list to resource name or -1
	.long	0		;# Resource attrs and offset from data start
	.long	0		;# Reserved for handle

name_list:
				;# No names, no name list
system_file_end:

#
# EOF
#

#
# test6.s
#
# sixth mac bootsector test
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
# The following causes a "sad mac" condition on my IIcx with codes 0000000f
# and 0000face (which means that we succesfully loaded 31k of data from the
# boot disk, starting at sector 2 (1k into the disk))
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
	tstw	%d0
	bmi	error

#
# Move to our new location
#

	movel	%a0, %sp@-
	movel	%a0, %a1
	leal	%pc@(blockstart), %a0
	movel	#0x400, %d0
	_BlockMove
	movel	%sp@+, %a0
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
# create an I/O parameter block on the stack and use it to read the next 31k
# of data from the disk.
#

	movew	#25, %d0
clearloop:
	clrw	%sp@-
	dbra	%d0, clearloop
	movel	%sp, %a0
	movew	#-5, %a0@(ioRefNum)	;# .Sony driver
	movew	BootDrive, %a0@(ioVRefNum)
	movew	#1, %a0@(ioPosMode)	;# absolute positioning
	movel	#0x400, %a0@(ioPosOffset);# second block
	movel	#0x7c00, %a0@(ioReqCount);# 31k of data (more than enough)
	lea	%pc@(secondstage), %a1
	movel	%a1, %a0@(ioBuffer)	;# read buffer address
	_Read
	addl	#50, %sp		;# clean up our mess
	tstw	%d0
	bnes	error			;# and check for errors

# disk read done, check the results

	movw	#0xf001, %d0

# check to see if we have the beginning	
	cmpil	#0x12345678, %pc@(secondstage)
	bnes	error

# check to see if we have the end
	movw	#0xbeef, %d0
	cmpil	#0x87654321, %pc@(end_secondstage)
	bnes	error

#
# Signal FACE
#

	movew	#0xface, %d0

#
# Our simple error handler
#

error:
	_SysError

	.balign 0x400
secondstage:
	.long	0x12345678

	.fill	0x7bf8
end_secondstage:
	.long	0x87654321

#
# EOF
#

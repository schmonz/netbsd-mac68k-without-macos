|
| bootsect.s
|
| bootsector code
|

	.include "traplist.i"
	.include "sysglobs.i"
	.include "structs.i"

|
| Boot block structure, from IM:Files, Chapter 2/Data Organization on Volumes
| "Boot Blocks". Sample data ripped from some System install disks (not like
| it matters, now does it?), and stripped to the minimum I found usable.
|

|
| Interestingly enough, it appears that only the first, fourth, and fifth
| words are sacred to the ROM startup code. If we _really_ needed the space,
| we could probably place our code starting where the System file name is
| supposed to be stored.
|
| The fifth word may also only be sacred to the original ROMs (see TN DV 03).
|

blockstart:
	.word	0x4c4b		;# boot signature
	bra	start		;# branch to code start (would be 0x008c for
				;# new-format block header)
	.word	0x4418		;# a version code of some sort
	.word	0x0000		;# Secondary sound and video buffer allocation
				;# (should always be 0, see retired TN DV 03)

|
| By now, we've covered all the boot block fields, and are ready to start in
| on some actual code.
|

start:

|
| This code initializes a system heap (which will need resizing later), copies
| itself into the start of a block allocated on the heap, sets up another block
| for the stack, loads the next 31k up from the disk, and jumps to it.
|
| This is actually rather minimal. We have 0x358 bytes left in which to work
| should we decide to add something to load the second stage init from a file
| on a UFS or Minix volume.
|

|
| First, set up the system heap
|

	moveal	SysZone, %a0
	addal	#0x20000, %a0	;# 256k of heap... Hope it's enough...
	_SetAppBase
	movel	SysZone, TheZone

|
| Next, allocate a block for us to use
|

	movel	#0x8000, %d0
	_NewPtr_Sys_Clear
	tstw	%d0
	bmi	error

|
| Move to our new location
|

	movel	%a0, %sp@-
	movel	%a0, %a1
	leal	%pc@(blockstart), %a0
	movel	#0x400, %d0
	_BlockMove
	movel	%sp@+, %a0
	jmp	%a0@(new_loc_target)

new_loc_target:

|
| Allocate a block for our stack
|

	movel	#0x4000, %d0
	_NewPtr_Sys_Clear
	tstw	%d0
	bmi	error
	addl	#0x4000, %a0
	movel	%a0, %sp

|
| create an I/O parameter block on the stack and use it to read the next 31k
| of data from the disk.
|
| Interestingly, from everything I've read, it should be possible to persuade
| this code to work on hard drives by changing the disk read code to look up
| the driver reference number (the -5 below) in the drive queue.  This, of
| course, relies on a working hard disk driver, which may be a problem, since
| Apple wants a special license for ROM patches to work around known bugs. Or
| we could continue to require MacOS to install the system in the first
| place... At least reducing the requirements to partitioning the disk makes
| it almost possible... Consider distributing a disk image with the disk tool
| patch on it, making it possible to do an install without having Stuffit or
| any similar tool... This is getting very far afield for a code comment...
| We could write a partition utility that grubs the nessecary patches out of
| the Apple disk tool binary, but that would require some HFS utilities at the
| very least... This is getting almost as bad as that place in the Linux kernel
| where there was a screen-sized comment on a one-line procedure...
|
| If we are booting a kernel in another partition, however, we still need to
| access the SCSI manager directly, since we can't get at the partition table
| any other way, and there is no obvious way to figure out which drive in the
| drive queue is which partition. This is probably a matter for the second
| stage loader, however...
|

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

| disk read done, jmp to it

	bra	secondstage

|
| Our simple error handler
|

error:
	_SysError

	.balign 0x400
secondstage:

|
| EOF
|

#
# test2.s
#
# second mac bootsector test
#

	.include "traplist.i"

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

	.word	0x4c4b		;# boot signature
	.word	0x6000, 0x0086	;# branch to code start (would be 0x008c for
				;# new-format block header)
	.word	0x4418		;# a version code of some sort
	.word	0x0000		;# Secondary sound and video buffer allocation
				;# (should always be 0, see retired TN DV 03)

	.long	0, 0, 0, 0	;# System file name (as pascal String[15])
	.long	0, 0, 0, 0	;# Finder file name
	.long	0, 0, 0, 0	;# Debugger file name
	.long	0, 0, 0, 0	;# Disassembler file name
	.long	0, 0, 0, 0	;# StartupScreen file name
	.long	0, 0, 0, 0	;# StartupProgram file name
	.long	0, 0, 0, 0	;# Clipboard file name

	.word	0x000a		;# Initial FCB allocation
	.word	0x0014		;# Event Queue allocation
	.long	0x00004300	;# 128k mac system heap size
	.long	0x00008000	;# "used internally" (256k mac system heap?)
	.long	0x00020000	;# "system heap size on all machines"

				;# new-format header fields (not used here)
#	.word	0x????		;# "filler"
#	.long	0x????????	;# "additional system heap space"
#	.long	0x????????	;# "fraction of RAM for system heap"

#
# By now, we've covered all the boot block fields, and are ready to start in
# on some actual code.
#

start:

#
# The following causes a "sad mac" condition on my IIcx with codes 0000000f
# and 0000face (implying, not incidentally, that the ROM loads the first 2
# sectors (1024 bytes) from the disk at startup, and not more).
#

	movw	#0xf001, %d0

# check to see if we have at least 1024 bytes	
	cmpil	#0x12345678, %pc@(testdata)
	bnes	fail

# check to see if we have more than 1024 bytes
	movw	#0xface, %d0
	cmpil	#0x87654321, %pc@(testdata2)
	bnes	fail

	movw	#0xbeef, %d0

fail:
	_SysError

	.balign	0x200
	.fill	0x1fc
testdata:
	.long	0x12345678
testdata2:
	.long	0x87654321
	
#
# EOF
#

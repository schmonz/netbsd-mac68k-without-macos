#
# resource.s
#
# Resource Manager routines
#

	.include "traplist.i"
	.include "structs.i"

	.global	init_resources
init_resources:

#
# Save the old addresses for the traps we need to replace
#

	movew	#0x11, %d0
	_GetTrapAddress_NewOS
	movel	%a0, %sp@-

	movew	#0x0a, %d0
	_GetTrapAddress_NewOS
	movel	%a0, %sp@-

	movew	#0x02, %d0
	_GetTrapAddress_NewOS
	movel	%a0, %sp@-

#
# Replace some file manager (and device manager) traps
#

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
# Put the traps back the way we found them (we need the real ones elsewhere,
# and the resource manager shouldn't be needing them anymore).
#

	movel	%sp@+, %a0
	movew	#0x02, %d0
	_SetTrapAddress_NewOS

	movel	%sp@+, %a0
	movew	#0x0a, %d0
	_SetTrapAddress_NewOS

	movel	%sp@+, %a0
	movew	#0x11, %d0
	_SetTrapAddress_NewOS

#
# And we're done
#

	rts

#
# Our file manager traps
#
# These are very simple implementations, intended only to fool the Resource
# Manager. To say that they are easily broken is an understatement.
#

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
error:
	_SysError

#
# Our fake system file (as empty as we can make it)
#

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

/* $NetBSD: bbstart.s,v 1.5 1999/02/16 23:34:11 is Exp $ */

/*-
 * Copyright (c) 1996 The NetBSD Foundation, Inc.
 * All rights reserved.
 *
 * This code is derived from software contributed to The NetBSD Foundation
 * by Ignatios Souvatzis.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *        This product includes software developed by the NetBSD
 *        Foundation, Inc. and its contributors.
 * 4. Neither the name of The NetBSD Foundation nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Excuse me while I hack this up a bit. --Alastair Bridgewater
 */

|
| Trap macros
|

#define _SysError		.word 0xa9c9
#define _SetAppBase		.word 0xa057
#define _NewPtr_Sys_Clear	.word 0xa71e
#define _BlockMove		.word 0xa02e
#define _Read			.word 0xa002

|
| IOParamBlock structure fields
|

ioVRefNum	=	22
ioRefNum	=	24
ioPosMode	=	44
ioPosOffset	=	46
ioBuffer	=	32
ioReqCount	=	36

|
| DrvQEl structure fields
|

qLink		=	0
dQDrive		=	6
dQRefNum	=	8

|
| System Globals
|

SysZone		=	0x2a6	| System heap zone
TheZone		=	0x118	| Current heap zone
BootDrive	=	0x210	| Drive number of the startup volume
DrvQHdr		=	0x308	| Drive Queue Header
BtDskRfn	=	0xb34	| Refnum of boot disk driver (NOT from IM)

|
| The code proper
|

#include "aout2bb.h"

	.globl	_pain

	.text
Lzero:
	.word	0x4c4b		| boot signature
	.globl _start
_start:
#if 1
	bra	Lloadremainder
#else
	bra	Lrelocate
#endif
	.word	0x4418		| a version code of some sort
	.word	0x0000		| Secondary sound and video buffer allocation
				| (should always be 0, see retired TN DV 03)
				| (may actually be specific to older ROMs)
	.word	0	|padding to align to long boundary

	/*
	 * We put the relocator version here, for aout2bb, which replaces
	 * it with the bootblock checksum.
	 */
Chksum:	.long RELVER_RELATIVE_BYTES_FORWARD
Filesz:	.long 8192			| dummy

Lreltab:
	.word 0			| aout2bb puts the reloc table address here

#if 1
Lloadremainder:
|
| This code initializes a system heap (which will need resizing later), copies
| itself into the start of a block allocated on the heap, sets up another block
| for the stack, loads the next 7k up from the disk, and jumps to it.
|

|
| First, set up the system heap
|

	moveal	SysZone, a0
	addal	#0x20000, a0	| 256k of heap... Hope its enough...
	_SetAppBase
	movel	SysZone, TheZone

|
| Next, allocate a block for us to use
|

	movel	#0x2000, d0
	_NewPtr_Sys_Clear
	tstw	d0
	bmi	Lerror

|
| Move to our new location
|

	movel	a0, sp@-
	movel	a0, a1
	lea	pc@(Lzero), a0
	movel	#0x400, d0
	_BlockMove
	movel	sp@+, a0
| the linker emits a relocation fixup for this jmp, but fixups arent applied
| yet. This is actually a good thing, since we want the unrelocated address.
	jmp	a0@(Lnew_loc_target)

Lnew_loc_target:

|
| Allocate a block for our stack
|

	movel	#0x4000, d0
	_NewPtr_Sys_Clear
	tstw	d0
	bmi	Lerror
	addl	#0x4000, a0
	movel	a0, sp

|
| run through the drive queue looking for the entry for the boot drive. This
| entry holds our driver reference number, which we need to pass to the read
| call below. Note that this will break if BootDrive isnt in the drive queue.
| (which is extremely unlikely, to say the least)
|
| NOTE: This didnt work, and I dont see why. However, 0xb34 supposedly is
| an s16 containing the driver reference number for the boot drive, so we
| can try using that instead.

|	movel	#DrvQHdr, a1
|	movew	BootDrive, a0
|Ldqp_loop:
|	cmpw	a1@(dQDrive), a0
|	beqs	Ldqp_done
|	movel	a1@(qLink), a1
|	bras	Ldqp_loop
|Ldqp_done:


|
| create an I/O parameter block on the stack and use it to read the next 7k
| of data from the disk.
|

	movew	#25, d0
Lclearloop:
	clrw	sp@-
	dbra	d0, Lclearloop
	movel	sp, a0
|	movew	#-5, a0@(ioRefNum)	| .Sony driver
|	movew	a1@(dQRefNum), a0@(ioRefNum)| the driver for the boot drive
	movew	BtDskRfn, a0@(ioRefNum)	| the driver for the boot drive (we hope)
	movew	BootDrive, a0@(ioVRefNum)
	movew	#1, a0@(ioPosMode)	| absolute positioning
	movel	#0x400, a0@(ioPosOffset)| second block
	movel	#0x1c00, a0@(ioReqCount)| 7k of data (just enough)
	lea	pc@(Lzero + 0x400), a1
	movel	a1, a0@(ioBuffer)	| read buffer address
	_Read
	addl	#50, sp			| clean up our mess
	tstw	d0
	bnes	Lerror			| and check for errors

| disk read done, jmp to it

	bra	Lrelocate

#endif

/*
 * Relocate ourselves, at the same time clearing the relocation table
 * (in case it overlaps with BSS).
 *
 * Register usage:
 * A2: points into the reloc table, located at our end.
 * A0: pointer to the longword to relocate.
 * D0: word offset of longword to relocate
 * D1: points to our start.
 *
 * Table has relative byte offsets, if a byte offset is zero, it is
 * followed by an absolute word offset. If this is zero, too, table
 * end is reached.
 */
 
Lrelocate:
	lea	pc@(Lzero),a0
	movl	a0,d1
	movw	pc@(Lreltab),a2
	addl	d1,a2
	jra	Loopend
	
Loopw:
	clrw	a2@+
	movl	d1,a0	| for a variant with relative words, erase this line
Loopb:
	addl	d0,a0
	addl	d1,a0@
Loopend:
	movq	#0,d0
	movb	a2@,d0
	clrb	a2@+	| bfclr a2@+{0:8} is still two shorts
	tstb	d0	| we could save one short by using casb d0,d0,a2@+
	jne	Loopb

	movw	a2@,d0
	jne	Loopw

Lendtab:

/* We are relocated. Now we call the main system */

	bsr	_pain

|
| Our simple error handler
|

	movew	#0xdead, d0
Lerror:
	_SysError

|
| The keyboard driver linkage (see keyboard.c)
|
	.globl _kb_driver_linkage
_kb_driver_linkage:
| I don't know what the reg preserve semantics are here, so I'm saving everything
| "Preserve all registers other than a0-a3 and d0-d3"... Whatever, Ill fix it later.
| Id also have to take the registers the compiler preserves into account...
| FIXME: This assembler doesnt like having an odd number of apostrophes in comments,
| which screws up too often.
	moveml	a0-a6/d0-d7, a7@-
	movel	d0, sp@-
	movel	a0, sp@-
	bsr	_kb_driver
	addql	#8, sp
	moveml	a7@+, a0-a6/d0-d7
	rts

/*
 * EOF
 */

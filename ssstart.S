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
	bra	Lrelocate

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

/* We are relocated. Now we set up the linkage to routines in stage 1 */

	addql	#4, a7
	movl	a7@+, L_putchar
	movl	a7@+, L_emit_string
	
/* Linkage done, now call the main system */

	bsr	_pain

|
| Our simple error handler
|

	movew	#0xb33f, d0
Lerror:
	_SysError

|
| linkage to routines in previous stage
|

	.globl	_emit_string
_emit_string:
	movel	(L_emit_string), a7@-
	rts
L_emit_string:
	.long	0

	.globl	_putchar
_putchar:
	movel	(L_putchar), a7@-
	rts
L_putchar:
	.long 0

|
| Final stage kernel startup
|
| Copy a small routine to just past the end of the environment buffer,
| set up a couple variables for it, and jump to it.
| This routine then relocates the kernel down to its final resting
| place and jumps to its entry point, completing the job.
|
|    boot_kernel(marks[MARK_START], marks[MARK_ENTRY], envbuf, envbuf_head+1);
#if 0
	.globl	_boot_kernel
_boot_kernel:
	addl	#4, a7		| discard our return address (its in the way)

	| SwapMMUMode to 32-bits
	| FIXME: Check this against IM:V
	movq	#1, d0
|	_SwapMMUMode
	.word	0xa05d

	movw	sr, d0		| disable interrupts
	oriw	#0x0700, d0
	movw	d0, sr

	movl	a7@+, a6	| start address
	movl	a7@+, a0	| entry point
	movl	a7@+, a1	| environment buffer
	movl	a7@+, a2	| end of environment buffer

	subl	a6, a0		| convert entry point to final value
	subl	a6, a1		| convert environment pointer to final value

	| copy final-stage jump to a safe place
	| FIXME: should use long transfers, not byte transfers
	movl	#Lcopiedcode, a3
	movl	#Lcopiedend-Lcopiedcode, d0
	movl	a2, a4
Lcopy1:	movb	a3@+, a4@+
	dbra	d0, Lcopy1

	| jump to copied code
	jmp	a2@

Lcopiedcode:
	| copy kernel to linear 0
	| FIXME: should use long transfers, not byte transfers
	subl	a6, a2
	movl	a2, d0
	movl	#0, a2
Lcopy2:	movb	a6@+, a2@+
	dbra	d0, Lcopy2

	| fake flags and start the kernel
	movl	#0x80000000, d4
	jmp	a0@
Lcopiedend:
#else
|	boot_kernel(marks[MARK_START],
|		    (((long)boot_kernel) - marks[MARK_START]) >> 2,
|		    marks[MARK_ENTRY] - marks[MARK_START],
|		    envbuf - marks[MARK_START]);

	.globl	_bootkern
_bootkern:
	addl	#4, a7		| discard our return address (its in the way)

	| SwapMMUMode to 32-bits
	| FIXME: Check this against IM:V
	movq	#1, d0
|	_SwapMMUMode
	.word	0xa05d

	movw	sr, d0		| disable interrupts
	oriw	#0x0700, d0
	movw	d0, sr

	movl	a7@+, a6	| start address
	movl	a7@+, d0	| length
	movl	a7@+, a0	| entry point
	movl	a7@+, a1	| environment buffer

	movl	#0, a4
Lcopy1:	movl	a6@+, a4@+
	dbra	d0, Lcopy1

	| kill the CPU caches
	movl	#0x808, d0	| '030 D and I cache clear and disable
	movc	d0, cacr

	| fake flags and start the kernel
	movl	#0x80000000, d4
	jmp	a0@

	.globl	_bootkern_end
_bootkern_end:

#endif

/*
 * EOF
 */

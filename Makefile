#
# Makefile for new macboot
#

DIR_TOP     = /usr/src/sys
DIR_SA      = ${DIR_TOP}/lib/libsa
DIR_KERN    = ${DIR_TOP}/lib/libkern
DIR_KERN_MD = ${DIR_TOP}/lib/libkern/arch/m68k

.PATH: ${DIR_SA} ${DIR_KERN} ${DIR_KERN_MD}

FILES = macboot
BINDIR = .

CC=gcc
AS=as
LD=ld

INCDIRS = -I${DIR_SA} -I${.CURDIR} -I${DIR_TOP}

DEFS = -D_STANDALONE -DINSECURE -DLIBSA_NO_TWIDDLE

HOST_CFLAGS=-Wall -O2
CFLAGS=${INCDIRS} ${DEFS} -Wall -O2 -ffixed-a5 -m68030
LDFLAGS=
SFLAGS= -l

default: macboot

macboot: aout2bb boot.out
	./aout2bb boot.out $@ || nm -u boot.out

aout2bb: aout2bb.c chksum.c
	$(CC) $(HOST_CFLAGS) -o $@ aout2bb.c chksum.c

boot.out: bbstart.o main.o resource.o keyboard.o console.o open.o ufs.o ashrdi3.o bzero.o strcmp.o strlen.o memcpy.o bcopy.o errno.o close.o read.o printf.o subr_prf.o
	$(LD) $(LDFLAGS) -r -dc -e _start -o $@ $>
	size $@
	nm -u $@

.c.o:
	$(CC) $(CFLAGS) -c $<

.s.o:
	$(AS) -o $@ $<

.S.o:
	$(CC) -c $<

#
# EOF
#

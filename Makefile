#
# Makefile for new macboot
#

DIR_TOP     = /usr/src/sys
DIR_SA      = ${DIR_TOP}/lib/libsa
DIR_Z       = ${DIR_TOP}/lib/libz
DIR_KERN    = ${DIR_TOP}/lib/libkern
DIR_KERN_MD = ${DIR_TOP}/lib/libkern/arch/m68k

.PATH: ${DIR_SA} ${DIR_Z} ${DIR_KERN} ${DIR_KERN_MD}

FILES = macboot stage2
BINDIR = .

CC=gcc
AS=as
LD=ld

INCDIRS = -I${DIR_SA} -I${DIR_Z} -I${.CURDIR} -I${DIR_TOP}

DEFS = -D_STANDALONE -DINSECURE -DLIBSA_NO_TWIDDLE -D__INTERNAL_LIBSA_CREAD

HOST_CFLAGS=-Wall -O2
CFLAGS=${INCDIRS} ${DEFS} -Wall -O2 -ffixed-a5 -m68030
LDFLAGS=
SFLAGS= -l

LIBZOBJS = crc32.o adler32.o inflate.o infutil.o infblock.o infcodes.o
LIBZOBJS+= inftrees.o inffast.o

COMMONOBJS = open.o close.o errno.o read.o lseek.o bd.o alloc.o# ufs.o ustarfs.o
COMMONOBJS+= memcpy.o strcmp.o strlen.o ashrdi3.o bzero.o bcopy.o ustarfs.o
COMMONOBJS+= memset.o panic.o strncmp.o closeall.o

STAGE1OBJS = bbstart.o main.o resource.o keyboard.o console.o alloc.o

STAGE2OBJS = ssstart.o loader.o loadfile.o memcmp.o strerror.o sprintf.o
STAGE2OBJS+= printf.o subr_prf.o cread.o $(LIBZOBJS)

default: machine macboot stage2

clean:
	rm -f *.o *.out *~ aout2bb macboot stage2

macboot: aout2bb boot.out
	./aout2bb boot.out $@ || nm -u boot.out

stage2: aout2bb stage2.out
	./aout2bb -S 28672 stage2.out $@ || nm -u stage2.out

aout2bb: aout2bb.c chksum.c
	$(CC) $(HOST_CFLAGS) -o $@ aout2bb.c chksum.c

boot.out: $(STAGE1OBJS) # $(COMMONOBJS)
	$(LD) $(LDFLAGS) -r -dc -e _start -o $@ $>
	size $@
	nm -u $@

stage2.out: $(STAGE2OBJS) $(COMMONOBJS)
	$(LD) $(LDFLAGS) -r -dc -e _start -o $@ $>
	size $@
	nm -u $@

machine:
	ln -s . machine

.c.o:
	$(CC) $(CFLAGS) -c $<

.s.o:
	$(AS) -o $@ $<

.S.o:
	$(CC) -c $<

#
# EOF
#

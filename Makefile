#
# Makefile for new macboot
#

CC=gcc
AS=as
LD=ld

HOST_CFLAGS=-Wall -O2
CFLAGS=-Wall -O2 -ffixed-a5 -m68000
LDFLAGS=
SFLAGS= -l

default: macboot

macboot: aout2bb boot.out
	./aout2bb boot.out $@ || nm -u boot.out

aout2bb: aout2bb.c chksum.c
	$(CC) $(HOST_CFLAGS) -o $@ aout2bb.c chksum.c

boot.out: bbstart.o main.o resource.o keyboard.o
	$(LD) $(LDFLAGS) -r -dc -e _start -o $@ $>
	size $@
	nm -u $@

.c.o: #txlt
	$(CC) $(CFLAGS) -c $<
#	$(CC) $(CFLAGS) -S $< -o $*.s
#	./txlt < $*.s | $(AS) $(AFLAGS) -o $*.o
#	rm $*.s

.s.o:
	$(AS) -o $@ $<

.S.o:
	$(CC) -c $<

# libsa stuff
S = /usr/src/sys
SADST = libsa
.include "$S/lib/libsa/Makefile.inc"

#
# EOF
#

#
# Makefile for Macboot
#

CC=m68k-coff-gcc
AS=m68k-coff-as
LD=m68k-coff-ld
RM=rm

LDFLAGS=-oformat binary
RMFLAGS=-f

TARGETS=test1.bin test2.bin test3.bin test4.bin test5.bin test6.bin mainapp.bin

MAINAPP_OBJS=bootsect.o mainapp.o resource.o graphics.o

default: $(TARGETS)

clean:
	$(RM) $(RMFLAGS) *.o *~ *.bin

.SUFFIXES: .o .s .bin .S

.s.o:
	$(AS) -o $@ $<

.S.o:
	$(CC) -c $<

.o.bin:
	$(LD) $(LDFLAGS) -o $@ $<

# special build rules
mainapp.bin: $(MAINAPP_OBJS)
	$(LD) $(LDFLAGS) -o mainapp.bin $(MAINAPP_OBJS)

#
# EOF
#

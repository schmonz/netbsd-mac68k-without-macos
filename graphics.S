|
| graphics.S
|
| QuickDraw interface and text box
|

	.include "traplist.i"
	.include "structs.i"
#include "appglobs.h"

|
| Variables local to this module
|

#define ourGrafPort localGrafPort(%a6)
#define ourLineWrapPosition localLineWrapPosition(%a6)
#define ourScrollRect localScrollRect(%a6)
#define ourRegionHandle localRegionHandle(%a6)
#define ourNewlinePoint localNewlinePoint(%a6)

localGrafPort:
	.space	sizeGrafPort

localScrollRect:
	.space	sizeRect

localNewlinePoint:
	.space	sizePoint

localLineWrapPosition:
	.word	0

localRegionHandle:
	.long	0

|
| Initialize QD and play with it
|

	.global	init_graphics
init_graphics:
	pea	thePort
	_InitGraf

	_InitFonts

	pea	ourGrafPort
	_OpenPort

|
| Lets draw a centered 450x300 framed white rectangle
|

| first, find the center of the screen

	movew	bottom + portRect + ourGrafPort, %d0
	movew	right + portRect + ourGrafPort, %d1
	lsrw	#1, %d0
	lsrw	#1, %d1

| second, use that to calculate the position of our rectangle

	addw	#225, %d1
	addw	#150, %d0
	movew	%d1, right + ourScrollRect
	movew	%d0, bottom + ourScrollRect
	subw	#450, %d1
	subw	#300, %d0
	movew	%d1, left + ourScrollRect
	movew	%d0, top + ourScrollRect

| third, fill our rectangle with white

	pea	ourScrollRect
	pea	white
	_FillRect

| fourth, frame our rectangle

	pea	ourScrollRect
	_FrameRect

| now, set the variables for managing the text box

	movew	left + ourScrollRect, %d0
	movew	bottom + ourScrollRect, %d1
	addqw	#4, %d0
	subqw	#4, %d1
	movew	%d0, left + ourNewlinePoint
	movew	%d1, top + ourNewlinePoint

	movew	right + ourScrollRect, %d0
	subiw	#14, %d0
	movew	%d0, ourLineWrapPosition

	addw	#10, top + ourScrollRect
	addqw	#1, left + ourScrollRect
	subqw	#1, bottom + ourScrollRect
	subqw	#1, right + ourScrollRect

	subql	#4, %sp
	_NewRgn
	movel	%sp@+, ourRegionHandle

	movel	ourNewlinePoint, %sp@-
	_MoveTo

	rts

	.global	emit_newline
emit_newline:
	pea	ourScrollRect
	movew	#0, %sp@-
	movew	#-12, %sp@-
	movel	ourRegionHandle, %sp@-
	_ScrollRect

	movel	ourNewlinePoint, %sp@-
	_MoveTo

	rts

	.global	emit_string
emit_string:
	movel	%sp@+, %a1
	movel	%sp@+, %a0
	movel	%a1, %sp@-
emit_string_loop:
	moveb	%a0@+, %d0
	beqs	emit_string_done
	movel	%a0, %sp@-
	bsrs	emit_char
	movel	%sp@+, %a0
	bras	emit_string_loop

emit_string_done:
	rts

	.globl	emit_limited_string
emit_limited_string:

emit_limited_string_loop:
	movel	%d0, %sp@-
	moveb	%a0@+, %d0
	beqs	emit_limited_string_cleanup
	movel	%a0, %sp@-
	bsrs	emit_char
	movel	%sp@+, %a0
	movel	%sp@+, %d0
	dbra	%d0, emit_limited_string_loop

emit_limited_string_done:
	rts
emit_limited_string_cleanup:
	addql	#4, %sp
	rts

	.global	emit_char
emit_char:
	cmpib	#0x0a, %d0
	beqs	emit_newline

	movew	%d1, %sp@-

	movew	ourLineWrapPosition, %d1
	cmpw	left + pnLoc + ourGrafPort, %d1
	bgt	emit_char_dont_scroll
	movew	%d0, %sp@-
	bsr	emit_newline
	movew	%sp@+, %d0

emit_char_dont_scroll:
	movew	%d0, %sp@-
	_DrawChar

	movew	%sp@+, %d1

	rts

	.global	emit_hex_long
emit_hex_long:
	movel	%d0, %sp@-
	lsrl	#8, %d0
	lsrl	#8, %d0
	bsrs	emit_hex_word
	movel	%sp@+, %d0

	.global	emit_hex_word
emit_hex_word:
	movew	%d0, %sp@-
	lsrw	#8, %d0
	bsrs	emit_hex_byte
	movew	%sp@+, %d0

	.global	emit_hex_byte
emit_hex_byte:
	movew	%d0, %sp@-
	lsrb	#4, %d0
	bsrs	emit_hex_nybble
	movew	%sp@+, %d0

emit_hex_nybble:
	andil	#0x0f, %d0
	lea	%pc@(hexchars), %a0
	adda	%d0, %a0
	moveb	(%a0), %d0
	bsrs	emit_char
	rts

hexchars:
	.ascii	"0123456789abcdef"

	.globl	dump_sector
dump_sector:
	movel	%a4, %sp@-
	movel	%a0, %a4

	clrw	%d0
|	movew	#0x1f, %d2
	movew	#0x0f, %d2

dump_sector_loop:
	movew	%d2, %sp@-
	movew	%d0, %sp@-
	bsr	emit_hex_word
	moveb	#':', %d0
	bsr	emit_char
	moveb	#' ', %d0
	bsr	emit_char

	movew	#0x0f, %d1
dump_sector_loop_2:
	moveb	%a4@+, %d0
	bsr	emit_hex_byte
	moveb	#' ', %d0
	bsr	emit_char
	dbf	%d1, dump_sector_loop_2

	moveb	#0x0a, %d0
	bsr	emit_char

	movew	%sp@+, %d0
	addw	#0x10, %d0
	movew	%sp@+, %d2
	dbf	%d2, dump_sector_loop

	movel	%sp@+, %a4
	rts

|
| EOF
|

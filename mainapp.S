|
| mainapp.S
|
| our application, such as it is
|

	.include "traplist.i"
	.include "structs.i"
	.include "sysglobs.i"
#include "appglobs.h"

secondstage:

|
| Set up our global variable space
|

	subl	#size_globs_above_a5, %sp
	moval	%sp, %a5
	subl	#size_globs_below_a5, %sp

|
| Set up various modules
|

	bsr	init_resources
	bsr	init_graphics
	bsr	show_greeting
	bsr	system_check

|
| Since we have nothing better to do, loop infinitely
|

	.word	0x60fe

|
| Greet the user
|

show_greeting:
	pea	%pc@(greet_string)
	bsr	emit_string

	rts

greet_string:
	.ascii	"---===***< Startup >***===---\n"
	.ascii	"graphics init: complete.\n"
|	.ascii	"really really long string to test the line wrap feature of"
|	.ascii	" our text box display thing. Hopefully this will be more than"
|	.ascii	" long enough.\n"
	.byte	0x00

|
| Check and display some system stats
|

system_check:
	pea	%pc@(memcheck_string)
	bsr	emit_string

	movel	MemTop, %d0
	bsr	emit_hex_long

	moveb	#'\n', %d0
	bsr	emit_char

	pea	%pc@(memcheck2_string)
	bsr	emit_string

	movel	BufPtr, %d0
	bsr	emit_hex_long

	moveb	#'\n', %d0
	bsr	emit_char

	rts

memcheck_string:
	.ascii	"MemTop = \0"

memcheck2_string:
	.ascii	"BufPtr = \0"

|
| EOF
|

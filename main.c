/*
 * main.c
 *
 * main functions or somesuch
 */

/*
 * important externals (probably want a separate header for these)
 */

void init_resources(void);

/*
 * experiments area
 */

#include "mactraps.h"

struct qd_globs our_qd_globs;
GrafPort our_grafport;
Rect our_scrollrect;
Point our_newline_point;
s16 our_linewrap_position;
RgnHandle our_region_handle;

void emit_newline(void)
{
    ScrollRect(&our_scrollrect, 0, -12, our_region_handle);
    MoveTo(our_newline_point);
}

void emit_char(char c)
{
    if (c == '\n') {
	emit_newline();
    } else {
	if (our_grafport.penState.pnLoc.h >= our_linewrap_position) {
	    emit_newline();
	}
	DrawChar(c);
    }
}

void emit_string(char *s)
{
    while (*s) {
	emit_char(*s++);
    }
}

void init_graphics()
{
    InitGraph(&our_qd_globs.thePort);

    InitFonts();
    
    OpenPort(&our_grafport);

    our_scrollrect.left = (our_grafport.portRect.right >> 1) - 225;
    our_scrollrect.right = our_scrollrect.left + 450;

    our_scrollrect.top = (our_grafport.portRect.bottom >> 1) - 150;
    our_scrollrect.bottom = our_scrollrect.top + 300;
    
    EraseRect(&our_scrollrect);
    FrameRect(&our_scrollrect);

    our_newline_point.h = our_scrollrect.left + 4;
    our_newline_point.v = our_scrollrect.bottom - 4;

    our_linewrap_position = our_scrollrect.right - 12;

    our_scrollrect.top += 10;
    our_scrollrect.bottom -= 1;
    our_scrollrect.left += 1;
    our_scrollrect.right -= 1;

    MoveTo(our_newline_point);

    our_region_handle = NewRgn();
}

#define fsFromStart 1

struct ParamBlockRec {
    void *qLink;
    s16 qType;
    s16 ioTrap;
    void *ioCmdAddr;
    void *ioCompletion;
    OSErr ioResult;
    char *ioNamePtr;
    s16 ioVRefNum;

    /* ioParam variant */
    s16 ioRefNum;
    s8 ioVersNum;
    s8 ioPermssn;
    void *ioMisc;
    void *ioBuffer;
    u32 ioReqCount;
    u32 ioActCount;
    s16 ioPosMode;
    s32 ioPosOffset;
};

extern inline OSErr PBRead(struct ParamBlockRec *paramblock)
{
    OSErr retval;

    asm("movel %1, a0; .word 0xa002; movew d0, %0": "=g" (retval): "g" (paramblock): ASM_REGS_DESTROYED);

    return retval;
}

extern inline OSErr PBWrite(struct ParamBlockRec *paramblock)
{
    OSErr retval;

    asm("movel %1, a0; .word 0xa003; movew d0, %0": "=g" (retval): "g" (paramblock): ASM_REGS_DESTROYED);

    return retval;
}

/* FIXME: Can anyone figure out a cleaner way to do this? */
#define ROMBase (*((void **)0x2ae))
#define BootDrive (*((u16 *)0x210))
#define BtDskRfn (*((s16 *)0xb34)) /* From "How to Write Macintosh Software",
				    * supposedly is available on the Mac Plus
				    * and presumably later systems. I wish
				    * I could find it in IM as well, since it
				    * would make me feel a lot safer about
	Hrm... It's kinda hard	    * using it. Oh well. If you find it doesn't
	to resist the urge to 	    * work, you'll have to fix the reference
	put some ascii art here	    * to it in bbstart.S as well, where there
				    * isn't such a long comment explaining my
				    * misgivings about it.
				    */

#if 0
/*
 * FIXME: I had to have this return the return from PBWrite to keep the
 * compiler from "optimizing" it out. If someone could tell me a better way?
 */
int dump_rom(void)
{
    struct ParamBlockRec paramblock;
    int i;
    
    emit_string("attempting to dump ROM to disk.\n");

    /* FIXME: Grr... No bzero(), no memset(), we roll our own. */
    for (i = 0; i < sizeof (paramblock); i += 2) {
	((u16 *)&paramblock)[i >> 1] = 0;
    }

    paramblock.ioVRefNum = BootDrive;
    paramblock.ioRefNum = BtDskRfn;
    paramblock.ioBuffer = ROMBase;
    paramblock.ioReqCount = 0x80000; /* 512K */
    paramblock.ioPosMode = fsFromStart;
    paramblock.ioPosOffset = 0;

    i = PBWrite(&paramblock);
    
    emit_string("ROM dump completed (hope it worked).\n");

    return i;
}
#endif

u8 read_key(void)
{
    struct EventRecord event;

    while (GetOSEvent(keyDownMask | autoKeyMask, &event))
	; /* do nothing */

    return event.message;
}

void emit_u8(u8 data)
{
    emit_char("0123456789abcdef"[data >> 4]);
    emit_char("0123456789abcdef"[data & 15]);
}

void emit_u16(u16 data)
{
    emit_u8(data >> 8);
    emit_u8(data);
}

void emit_u32(u32 data)
{
    emit_u16(data > 16);
    emit_u16(data);
}

/*
 * m^Hpain function
 */

void pain(void)
{
    init_resources();

    init_graphics();

/*      SysEvtMask = everyEvent; */
/*      FlushEvents(everyEvent, 0); */

    emit_string("---===***< Startup >***===---\n");
#if 0
    emit_string("Really really really long line to test the line wrapping "
		"feature of emit_char(). ABCDEFGHIJKLMNOPQRSTUVWXYZ "
		"abcdefghijklmnopqrstuvwxyz.\n");
#endif
    InitEvents(0x20);
    SysEvtMask = keyDownMask | autoKeyMask;
    FlushEvents(everyEvent, 0);
    install_kb_driver();
/*      InitCursor(); */
/*      { u16 tmp; asm("movew sr, %0": "=g" (tmp)); emit_u16(tmp); emit_char('\n');} */
/*      emit_u16(SysEvtMask); */
/*      emit_char('\n'); */

/*     dump_rom(); */

    emit_string("> ");
/*      while(1); */
    while (1) {
	emit_char(read_key());
    }

    while(1);
}

/*
 * EOF
 */

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

#define ASM_REGS_DESTROYED "a0", "a1", "d0", "d1", "d2"

typedef unsigned char u8;
typedef signed char s8;
typedef unsigned short u16;
typedef signed short s16;
typedef unsigned long u32;
typedef signed long s32;

typedef struct Point Point;
typedef struct Rect Rect;

typedef struct Region Region;
typedef Region *RgnPtr, **RgnHandle;

typedef struct PenState PenState;

typedef struct BitMap BitMap;

typedef void *QDProcsPtr;
typedef void *Ptr, **Handle;

typedef struct Pattern Pattern, *PatPtr, **PatHandle;
typedef const u8 *ConstPatternParam;

typedef struct GrafPort GrafPort, *GrafPtr;

typedef s32 Fixed;
typedef u16 Style;

struct qd_globs {
    char reserved[202];
    GrafPtr thePort;
    GrafPtr *a5_target;
};

struct Point {
    s16 v;
    s16 h;
};

struct Rect {
    s16 top;
    s16 left;
    s16 bottom;
    s16 right;
};

struct BitMap {
    Ptr baseAddr;
    s16 rowBytes;
    Rect bounds;
};

struct Pattern {
    u8 pat[8];
};

struct PenState {
    Point pnLoc;
    Point pnSize;
    s16 pnMode;
    Pattern pnPat;
};

struct GrafPort {
    s16 device;
    BitMap portBits;
    Rect portRect;
    RgnHandle visRgn;
    RgnHandle clipRgn;
    Pattern bkPat;
    Pattern fillPat;
    PenState penState;
    s16 pnVis;
    s16 txFont;
    Style txFace;
    u8 filler;
    s16 txMode;
    s16 txSize;
    Fixed spExtra;
    s32 fgColor;
    s32 bkColor;
    s16 colrBit;
    s16 patStretch;
    Handle picSave;
    Handle rgnSave;
    Handle polySave;
    QDProcsPtr grafProcs;
};

extern inline void EraseRect(Rect *r)
{
    asm("movel %0, sp@-; .word 0xa8a3": : "a" (r): ASM_REGS_DESTROYED);
}

extern inline void FrameRect(Rect *r)
{
    asm("movel %0, sp@-; .word 0xa8a1": : "a" (r): ASM_REGS_DESTROYED);
}

extern inline void InitGraph(GrafPtr *port)
{
    asm("lea %0@(4), a5; movel %0, sp@-; .word 0xa86e": : "a"(port): ASM_REGS_DESTROYED);
}

extern inline void OpenPort(GrafPtr port)
{
    asm("movel %0, sp@-; .word 0xa86f": : "a"(port): ASM_REGS_DESTROYED);
}

extern inline void InitFonts(void)
{
    asm(".word 0xa8fe": : : ASM_REGS_DESTROYED);
}

extern inline void MoveTo(Point point)
{
    asm("movel %0, sp@-; .word 0xa893": : "m" (point): ASM_REGS_DESTROYED);
}

extern inline RgnHandle NewRgn(void)
{
    RgnHandle retval;

    asm("subql #4, sp; .word 0xa8d8; movel sp@+, %0": "=g" (retval): : ASM_REGS_DESTROYED);

    return retval;
}

extern inline void DrawChar(char acter)
{
    asm("movew %0, sp@-; .word 0xa883": : "g" (acter): ASM_REGS_DESTROYED);
}

extern inline void ScrollRect(Rect *rect, s16 h, s16 v, RgnHandle updateregion)
{
    asm("movel %0, sp@-; movew %1, sp@-; movew %2, sp@-; movel %3, sp@-; .word 0xa8ef": : "g" (rect), "g" (h), "g" (v), "g" (updateregion): ASM_REGS_DESTROYED);
}

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

typedef s16 OSErr;

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

/*
 * m^Hpain function
 */

void pain(void)
{
    init_resources();

    init_graphics();

    emit_string("---===***< Startup >***===---\n");
#if 0
    emit_string("Really really really long line to test the line wrapping "
		"feature of emit_char(). ABCDEFGHIJKLMNOPQRSTUVWXYZ "
		"abcdefghijklmnopqrstuvwxyz.\n");
#endif

    dump_rom();
    
    while(1);
}

/*
 * EOF
 */

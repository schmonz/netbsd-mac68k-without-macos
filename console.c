/*
 * $Id$
 *
 * boot console
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

void putchar(char c)
{
    if (c == '\n') {
	emit_newline();
    } else if (c == '\b') {
      /* FIXME: character erase semantics? */
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
	putchar(*s++);
    }
}

void init_graphics()
{
    InitGraph(&our_qd_globs.thePort);

    InitFonts();
    
    OpenPort(&our_grafport);

    /* set font Monaco-9 (a fixed width font, IM:V says it's in the SE and II ROMs) */
    TextFont(4);
    TextSize(9);

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

void init_console(void)
{
    init_resources();
    init_graphics();

    InitEvents(0x20);
    SysEvtMask = keyDownMask | autoKeyMask;
    FlushEvents(everyEvent, 0);
    install_kb_driver();
}

/* EOF */

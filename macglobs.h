/*
 * macglobs.h
 *
 * MacOS Global Variables
 */

#include "mactypes.h"

/* FIXME: Can anyone figure out a cleaner way to do this? */
#define ROMBase (*((void **)0x2ae))
#define TimeDBRA (*((u16 *)0xd00))
#define HWCfgFlags (*((u16 *)0xb22))
#define BootDrive (*((u16 *)0x210))
#define ApplZone (*((u32 *)0x2aa)) /* FIXME: Should be void ** */
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

/* EOF */

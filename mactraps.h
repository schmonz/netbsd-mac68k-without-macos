/*
 * mactraps.h
 *
 * MacOS system traps.
 */

#ifndef MACTRAPS_H
#define MACTRAPS_H

#include "mactypes.h"

#define ASM_REGS_DESTROYED "a0", "a1", "d0", "d1", "d2"


/* Various traps */

extern inline void SysError(u16 code)
{
    asm volatile("movw %0, d0; .word 0xa9c9": : "g" (code): ASM_REGS_DESTROYED);
}

extern inline void *NewPtr_Sys_Clear(u32 size)
{
    void *retval;

    asm volatile("movel %1, d0; .word 0xa71e; movel a0, %0": "=g" (retval): "g" (size): ASM_REGS_DESTROYED);

    return retval;
}

extern inline void DisposPtr(void *ptr)
{
    asm volatile("movel %0, a0; .word 0xa01f": : "g" (ptr): ASM_REGS_DESTROYED);
}

/* QuickDraw traps */

extern inline void EraseRect(Rect *r)
{
    asm volatile("movel %0, sp@-; .word 0xa8a3": : "a" (r): ASM_REGS_DESTROYED);
}

extern inline void FrameRect(Rect *r)
{
    asm volatile("movel %0, sp@-; .word 0xa8a1": : "a" (r): ASM_REGS_DESTROYED);
}

extern inline void InitGraph(GrafPtr *port)
{
    asm volatile("lea %0@(4), a5; movel %0, sp@-; .word 0xa86e": : "a"(port): ASM_REGS_DESTROYED);
}

extern inline void OpenPort(GrafPtr port)
{
    asm volatile("movel %0, sp@-; .word 0xa86f": : "a"(port): ASM_REGS_DESTROYED);
}

extern inline void InitFonts(void)
{
    asm volatile(".word 0xa8fe": : : ASM_REGS_DESTROYED);
}

extern inline void MoveTo(Point point)
{
    asm volatile("movel %0, sp@-; .word 0xa893": : "m" (point): ASM_REGS_DESTROYED);
}

extern inline RgnHandle NewRgn(void)
{
    RgnHandle retval;

    asm volatile("subql #4, sp; .word 0xa8d8; movel sp@+, %0": "=g" (retval): : ASM_REGS_DESTROYED);

    return retval;
}

extern inline void DrawChar(char acter)
{
    asm volatile("movew %0, sp@-; .word 0xa883": : "g" (acter): ASM_REGS_DESTROYED);
}

extern inline void TextFont(s16 font)
{
    asm volatile("movew %0, sp@-; .word 0xa887": : "g" (font): ASM_REGS_DESTROYED);
}

extern inline void TextSize(s16 size)
{
    asm volatile("movew %0, sp@-; .word 0xa88a": : "g" (size): ASM_REGS_DESTROYED);
}

extern inline void ScrollRect(Rect *rect, s16 h, s16 v, RgnHandle updateregion)
{
    asm volatile("movel %0, sp@-; movew %1, sp@-; movew %2, sp@-; movel %3, sp@-; .word 0xa8ef": : "g" (rect), "g" (h), "g" (v), "g" (updateregion): ASM_REGS_DESTROYED);
}

extern inline void InitCursor(void)
{
    asm volatile(".word 0xa850": : : ASM_REGS_DESTROYED);
}

/* Operating System Event Manager traps */

extern inline void InitEvents(u16 numQEntries)
{
    /*
     * Undocumented trap 0xa06d: takes a word in d0 containing the number of system event queue
     * entries to create, returns nothing. Enables the OS Event Manager (must be called before
     * GetOSEvent()). If any Apple people are reading this, I would appreciate knowing what the
     * official names are for both this trap and trap 0xa06c, which does the same with a number
     * of FCBs for the File Manager.
     */
    asm volatile("movew %0, d0; .word 0xa06d": : "g" (numQEntries): ASM_REGS_DESTROYED);
}

extern inline OSErr PostEvent(u16 eventtype, u32 message)
{
    OSErr retval;

    asm volatile("movew %1, a0; movel %2, d0; .word 0xa02f; movew d0, %0": "=g" (retval): "g" (eventtype), "g" (message): ASM_REGS_DESTROYED);

    return retval;
}

extern inline s16 GetOSEvent(u16 eventMask, struct EventRecord *theEvent)
{
    s8 retval;

    asm volatile("movew %1, d0; movel %2, a0; .word 0xa031; movew d0, %0": "=g" (retval): "g" (eventMask), "g" (theEvent): ASM_REGS_DESTROYED);

    return retval;
}

extern inline u16 FlushEvents(u16 eventMask, u16 stopMask)
{
    u16 retval;
    u32 tmp;

    tmp = eventMask | (stopMask << 16);
    asm volatile("movel %1, d0; .word 0xa032; movew d0, %0": "=g" (retval): "g" (tmp): ASM_REGS_DESTROYED);

    return retval;
}

/* ADB Manager traps */

extern inline void ADBReInit(void)
{
    asm volatile(".word 0xa07b": : : ASM_REGS_DESTROYED);
}

extern inline OSErr ADBOp(struct ADBOpPB *pb, s16 command)
{
    OSErr retval;

    asm volatile("movel %1, a0; movew %2, d0; .word 0xa07c; movew d0, %0": "=g" (retval): "g" (pb), "g" (command): ASM_REGS_DESTROYED);

    return retval;
}

extern inline s16 CountADBs(void)
{
    s8 retval;

    asm volatile(".word 0xa077; moveb d0, %0": "=g" (retval): : ASM_REGS_DESTROYED);

    return retval;
}

extern inline ADBAddress GetIndADB(struct ADBDataBlock *info, s16 devTableIndex)
{
    ADBAddress retval;

    asm volatile("movel %1, a0; movew %2, d0; .word 0xa078; moveb d0, %0": "=g" (retval): "g" (info), "g" (devTableIndex): ASM_REGS_DESTROYED);

    return retval;
}

extern inline OSErr GetADBInfo(struct ADBDataBlock *info, ADBAddress ADBAddr)
{
    OSErr retval;

    asm volatile("movel %1, a0; moveb %2, d0; .word 0xa079; movew d0, %0": "=g" (retval): "g" (info), "g" (ADBAddr): ASM_REGS_DESTROYED);

    return retval;
}

extern inline OSErr SetADBInfo(struct ADBSetInfoBlock *info, ADBAddress ADBAddr)
{
    OSErr retval;

    asm volatile("movel %1, a0; moveb %2, d0; .word 0xa07a; movew d0, %0": "=g" (retval): "g" (info), "g" (ADBAddr): ASM_REGS_DESTROYED);

    return retval;
}

/* File/Device Manager traps */

extern inline OSErr PBRead(struct ParamBlockRec *paramblock)
{
    OSErr retval;

    asm volatile("movel %1, a0; .word 0xa002; movew d0, %0": "=g" (retval): "g" (paramblock): ASM_REGS_DESTROYED);

    return retval;
}

extern inline OSErr PBWrite(struct ParamBlockRec *paramblock)
{
    OSErr retval;

    asm volatile("movel %1, a0; .word 0xa003; movew d0, %0": "=g" (retval): "g" (paramblock): ASM_REGS_DESTROYED);

    return retval;
}

#endif /* MACTRAPS_H */

/* EOF */

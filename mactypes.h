/*
 * mactypes.h
 *
 * MacOS system datatypes
 */

#ifndef MACTYPES_H
#define MACTYPES_H

typedef unsigned char u8;
typedef signed char s8;
typedef unsigned short u16;
typedef signed short s16;
typedef unsigned long u32;
typedef signed long s32;

typedef s16 OSErr;

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

/* OS Event Manager types */

#define nullEvent   0
#define mouseDown   1
#define mouseUp     2
#define keyDown     3
#define keyUp       4
#define autoKey     5
#define updateEvt   6
#define diskEvt     7
#define activateEvt 8
#define networkEvt  10
#define driverEvt   11
#define app1Evt     12
#define app2Evt     13
#define app3Evt     14
#define app4Evt     15

#define mDownMask   0x0002
#define mUpMask     0x0004
#define keyDownMask 0x0008
#define keyUpMask   0x0010
#define autoKeyMask 0x0020
#define updateMask  0x0040
#define diskMask    0x0080
#define activMask   0x0100
#define networkMask 0x0400
#define driverMask  0x0800
#define app1Mask    0x1000
#define app2Mask    0x2000
#define app3Mask    0x4000
#define app4Mask    0x8000
#define everyEvent  0xffff

#define SysEvtMask *((u16 *)0x144)

struct EventRecord {
    s16 what;
    s32 message;
    s32 when;
    struct Point where;
    s16 modifiers;
};

/* ADB Manager types */

typedef u8 ADBAddress;

struct ADBDataBlock {
    s8 devType;
    s8 origADBAddr;
    void *dbServiceRtPtr;
    void *dbDataAreaAddr;
} __attribute__ ((packed));

struct ADBSetInfoBlock {
    void *siServiceRtPtr;
    void *siDataAreaAddr;
};

struct ADBOpPB {
    void *buffer;
    void *compRout;
    void *data;
};

/* File/Device Manager types */

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
} __attribute__ ((packed));

#endif /* MACTYPES_H */

/* EOF */

/*
 * main.c
 *
 * main functions or somesuch
 */

#include "stand.h"

/*
 * experiments area
 */

#include "mactraps.h"

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
void dump_rom(void)
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

    PBWrite(&paramblock);
    
    emit_string("ROM dump completed (hope it worked).\n");
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
    putchar("0123456789abcdef"[data >> 4]);
    putchar("0123456789abcdef"[data & 15]);
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

void cat_file(char *filename)
{
    int fd;
    int i;
    int j;
    char buf[128];
    fd = open(filename, 0);
    if (fd < 0) {
	emit_string("file not found.\n");
	emit_u32(errno);
	putchar('\n');
	return;
    }
    while((i = read(fd, buf, 128)) > 0) {
	for (j = 0; j < i; j++) {
	    putchar(buf[j]);
	}
    }
    close(fd);
}

/*
 * "bd" (bios disk) device interface
 */

#include "ufs.h"

/*  #define XDDEBUG */

static int bdstrategy __P((void *, int, daddr_t, size_t, void *, size_t *));
static int bdopenclose __P((struct open_file *));
static int bdioctl __P((struct open_file *, u_long, void *));

static struct devsw devsw[] = {
        { "bd", bdstrategy, (void *)bdopenclose, (void *)bdopenclose, bdioctl }
};              

struct fs_ops file_system[] = {
	{ ufs_open, ufs_close, ufs_read, ufs_write, ufs_seek, ufs_stat },
};

int nfsys = sizeof(file_system)/sizeof(struct fs_ops);

int devopen(struct open_file *f, const char *fname, char **file)
{
	f->f_devdata = 0;
	f->f_dev = &devsw[0];
	*file = (char *)fname;
	return 0;
}
static int
bdstrategy (devd, flag, dblk, size, buf, rsize)
	void	*devd;
	int     flag;
	daddr_t dblk;
	size_t  size;
	void    *buf;
	size_t  *rsize; 
{
    struct ParamBlockRec paramblock;

    if (flag != F_READ)
	return EIO;

    paramblock.ioVRefNum = BootDrive;
    paramblock.ioRefNum = BtDskRfn;
    paramblock.ioReqCount = size;
    paramblock.ioPosMode = fsFromStart;
    paramblock.ioPosOffset = (dblk << 9);
    paramblock.ioBuffer = buf;

#ifdef XDDEBUG
    printf("strategy called: %ld(%ld), %ld, 0x%lx\n",
	   (long)dblk, (long)paramblock.ioPosOffset, (long)size, (unsigned long)buf);
#endif

    PBRead(&paramblock);

#ifdef XDDEBUG
    printf("strategy got err %ld, rsize %ld\n", (long)paramblock.ioResult, paramblock.ioActCount);
#endif

    if (paramblock.ioResult) {
	*rsize = 0;
	return EIO;
    }

    *rsize = paramblock.ioActCount;
    return 0;
}


/* nothing do do for these: */

static int
bdopenclose(f)
	struct open_file *f;
{
	return 0;
}

static int
bdioctl (f, cmd, data)
	struct open_file *f;
	u_long  cmd;
	void    *data;
{
	return EIO;
}

/*
 * memory allocation
 */

void *alloc(unsigned int size)
{
    return NewPtr_Sys_Clear(size);
}

void free(void *ptr, unsigned int foo)
{
    DisposPtr(ptr);
}

/*
 * m^Hpain function
 */

void pain(void)
{
    init_console();

    emit_string("---===***< Startup >***===---\n");
#if 0
    emit_string("Really really really long line to test the line wrapping "
		"feature of emit_char(). ABCDEFGHIJKLMNOPQRSTUVWXYZ "
		"abcdefghijklmnopqrstuvwxyz.\n");
#endif

/*      cat_file("test.txt"); */
    cat_file("netbsd");

    emit_string("> ");
    while (1) {
	putchar(read_key());
    }

    while(1);
}

/*
 * EOF
 */

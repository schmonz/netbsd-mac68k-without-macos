/*
 * "bd" (bios disk) device interface
 */

#include "stand.h"
#include "ufs.h"
#include "mactypes.h"
#include "mactraps.h"
#include "macglobs.h"

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

/* EOF */

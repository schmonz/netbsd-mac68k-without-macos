/*
 * loader.c
 *
 * load a kernel from the disk and boot it
 */

#include "stand.h"
#include <a.out.h>
#include "loadfile.h"
#include "macglobs.h"

char *envbuf;
char *envbuf_head;

void init_envbuf(void *start)
{
    envbuf = envbuf_head = start;
    *envbuf_head++ = 0;
    *envbuf_head = 0;
}

void setenv(const char *var, long val)
{
    envbuf_head += sprintf(envbuf_head, "%s=%lu", var, val);
    *++envbuf_head = 0; /* Yes, I know this looks odd. Don't mess with it. */
}

void dump_environment(void)
{
    char *p;

    p = envbuf + 1;
    while (*p) {
#ifdef LIBSA_FAILS_TO_SUCK
	p += printf("%s\n", p); /* WTF?!? */
#else
	printf("%s\n", p);
	while (*p++);
#endif
    }
}

void pain(void)
{
    u_long marks[MARK_MAX];

    printf("... stage2 now running.\nLoading netbsd.gz...\n");
    
    /*
     * There's no application, and we're using the system heap for all our
     * allocations, so we can just load the kernel starting where the
     * application zone would have and not have to deal with calling loadfile
     * twice the way the amiga boot does since we don't need to know how
     * large it is. This will break if there isn't enough memory, but that's
     * hardly likely at this point.
     */
    marks[MARK_START] = ApplZone;
    if (loadfile("netbsd.gz", marks,
		 LOAD_TEXT|LOAD_TEXTA|LOAD_DATA|LOAD_BSS|LOAD_SYM) == -1) {
	printf("kernel load failure.\n");
	while(1);
    }

    printf("initializing environment buffer...\n");

    init_envbuf((marks[MARK_END] + 7) & ~3);

    /* Environment values made up as I went along */
    /* FIXME: These should be looked up in the MacOS environment */
    setenv("VIDEO_ADDR", 0xfe008040);
    setenv("ROW_BYTES", 64);
    setenv("SCREEN_DEPTH", 1);
    setenv("DIMENSIONS", 512 | (342 << 16));

    setenv("MACHINE_ID", 9);
    setenv("PROCESSOR", 1);
    setenv("MEMSIZE", 8);
    setenv("BOOTERVER", 111);

    setenv("ROMBASE", ROMBase);
    setenv("TIMEDBRA", TimeDBRA);
    setenv("ADBDELAY", *((u16 *)0xcea));
    setenv("HWCFGFLAGS", HWCfgFlags);
    setenv("HWCFGFLAG2", *((u32 *)0xdd0));
    setenv("HWCFGFLAG3", *((u32 *)0xdd4));
    setenv("ADBREINIT_JTBL", *((u32 *)0xdd8));

    setenv("END_SYM", marks[MARK_END] - marks[MARK_START]);

#if 0
    printf("marks:\n  START: %p\n  ENTRY: %p\n  NSYM: %ld\n  END: %p\n",
	   marks[MARK_START], marks[MARK_ENTRY],
	   marks[MARK_NSYM], marks[MARK_END]);
    dump_environment();
#endif
    {
	extern void bootkern;
	extern void bootkern_end;
	void (*boot_kernel)(long, long, long, long);

	boot_kernel = (((long)envbuf_head) + 5) & ~3;
	bcopy(&bootkern, boot_kernel, &bootkern_end - &bootkern);
	boot_kernel(marks[MARK_START],
		    (((long)boot_kernel) - marks[MARK_START]) >> 2,
		    marks[MARK_ENTRY] - marks[MARK_START],
		    envbuf - marks[MARK_START]);
    }
/*     boot_kernel(marks[MARK_START], marks[MARK_ENTRY], envbuf, envbuf_head+1); */
    
    while(1);
}

/* EOF */

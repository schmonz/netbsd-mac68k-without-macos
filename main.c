/*
 * main.c
 *
 * main functions or somesuch
 */

#include "stand.h"
#include "mactypes.h"
#include "mactraps.h"
#include "macglobs.h"

/*
 * experiments area
 */

void emit_string(char *s); /* FIXME: Put in console.h */

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
    emit_u16(data >> 16);
    emit_u16(data);
}

#if 0
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
#endif


/*
 * stage2 loading
 */

void load_stage_2(void)
{
#if 0
    int fd;
    int size;
#else
    struct ParamBlockRec paramblock;
#endif
    void *buffer;
    void (*start)(void *, void *);

    /* FIXME: More error checking */
    
#if 0
    fd = oopen("stage2", 0);
    if (fd < 0) {
	emit_string("stage2 not found.\n");
	emit_u32(errno);
	putchar('\n');
	return;
    }
    size = olseek(fd, 0, SEEK_END);
    olseek(fd, 0, SEEK_SET);
    buffer = alloc(size);
    oread(fd, buffer, size);
    oclose(fd);
    start = buffer + 2;
#else
    buffer = alloc(32768);
    paramblock.ioVRefNum = BootDrive;
    paramblock.ioRefNum = BtDskRfn;
    paramblock.ioReqCount = 32768;
    paramblock.ioPosMode = fsFromStart;
    paramblock.ioPosOffset = 8192 + 512;
    paramblock.ioBuffer = buffer;
    PBRead(&paramblock);
    start = buffer + 2;
#endif

    /* FIXME: make the linkage interface cleaner */
    start(putchar, emit_string);
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
/*     cat_file("netbsd"); */

    emit_string("Loading stage 2...\n");
    load_stage_2();

#if 0
    emit_string("> ");
    while (1) {
	putchar(read_key());
    }
#endif

    while(1);
}

/*
 * EOF
 */

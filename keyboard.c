/*
 * keyboard.c
 *
 * ADB keyboard driver
 */

/*
 * Eitehr Mac II era ROMs don't have keyboard drivers, or they require special setup provided by the
 * System file's ADBS.2 resource. We don't have the system file, and can't use it's driver code, so
 * we roll our own. Fun fun. On the upside, at least we don't need to do everything that the normal
 * MacOS keyboard driver does, since we have a more restricted application involved...
 */

#include "mactraps.h"

/*
 * There is a small amount of glue logic somewhere providing a linkage for the driver proc, so
 * we can write it in C.
 */

extern void kb_driver_linkage;

u8 keytrans[0x40][2] = {
    /* 00 - 0f */
    {'a', 'A'},    {'s', 'S'},    {'d', 'D'},    {'f', 'F'},
    {'h', 'H'},    {'g', 'G'},    {'z', 'Z'},    {'x', 'X'},
    {'c', 'C'},    {'v', 'V'},    {0, 0},        {'b', 'B'},
    {'q', 'Q'},    {'w', 'W'},    {'e', 'E'},    {'r', 'R'},

    /* 10 - 1f */
    {'y', 'Y'},    {'t', 'T'},    {'1', '!'},    {'2', '@'},
    {'3', '#'},    {'4', '$'},    {'6', '^'},    {'5', '%'},
    {'=', '+'},    {'9', '('},    {'7', '&'},    {'-', '_'},
    {'8', '*'},    {'0', ')'},    {']', '}'},    {'o', 'O'},

    /* 20 - 2f */
    {'u', 'U'},    {'[', '{'},    {'i', 'I'},    {'p', 'P'},
    {'\n', '\n'},  {'l', 'L'},    {'j', 'J'},    {'\'', '"'},
    {'k', 'K'},    {';', ':'},    {'\\', '|'},   {',', '<'},
    {'/', '?'},    {'n', 'N'},    {'m', 'M'},    {'.', '>'},

    /* 30 - 3f */
    {'\t', '\t'},  {' ', ' '},        {'`', '~'},    {'\b', '\b'},
};

u8 shiftstate;
u8 lockstate;

void kb_driver(u8 *buffer, u8 command)
{
    int i;

    if ((command & 0x0f) == 0x0c) {
	/* Only Talk Register 0 commands */
	for (i = *buffer; i; i--) {
	    buffer++;
	    if ((*buffer != 0xff) && ((*buffer & 0x7f) < 0x40)) {
		/* ignoring keycodes >= 0x40 since they are keypad, cursor control, and fkeys */
		/* handle bucky bit control first */
		if (*buffer == 0x38) shiftstate = 1;
		else if (*buffer == 0xb8) shiftstate = 0;
		else if (*buffer == 0x39) lockstate = 1;
		else if (*buffer == 0xb9) lockstate = 0;
		if (keytrans[*buffer & 0x7f][0]) {
		    PostEvent((*buffer & 0x80)? keyUp: keyDown, keytrans[*buffer & 0x7f][shiftstate | lockstate]);
		}
	    }
	}
    }
}

void install_kb_driver(void)
{
    ADBAddress addr;
    struct ADBDataBlock data1;
    struct ADBSetInfoBlock data2;
    int num_devs;
    int i;

    shiftstate = 0;
    lockstate = 0;

    num_devs = CountADBs();
    for (i = 0; i < num_devs; i++) {
	addr = GetIndADB(&data1, i+1);
	if (data1.origADBAddr == 2) {
	    /* It's a keyboard */
	    data2.siServiceRtPtr = &kb_driver_linkage;
	    data2.siDataAreaAddr = 0;
	    SetADBInfo(&data2, addr);
	}
    }
}

/* EOF */

#
# Notes on the native bootstrap system
#

This is a native-boot solution for 68k-based macs with II-series ROMs.

The base code for the boot sequence has been tested on both an SE/30
and a IIcx. The kernel environment parameters are presently hardcoded
for an SE/30 with 8 megs of RAM.

This code was tried on a Performa 400 (LCII), but it failed miserably
(sad mac on startup).

This code was developed on a 1.5.1 (a.out) system, and may need to be
compiled in such an environment.

Because the basic goal was to load an install kernel from a floppy
disk we are using ustarfs (the only way to get the install kernel to
fit on a 1.44 meg disk).

To build a disk image with this code, compile with make, then use
pax to create a ustar archive with the stage2 file and your kernel
(which can be either ELF or a.out, and must be named 'netbsd.gz')
as follows:

    pax -x ustar -w -f ustar.img stage2 netbsd.gz

Next, concatenate the macboot file with the new ustar archive to
create the disk image:

    cat macboot ustar.img > disk_image

A disk made with this image can now be used to boot an SE/30.


Parts of this code have been derived from NetBSD kernel sources
and from the source to Booter version 1.11.3.

Thanks to Michael R. Zucca, Henry B. Hotz, Allen Briggs,
Robert Swindells, and Brendan Burns for encouragement, discussion
of possibilities, and prompting. 29 months, and we -finally- have
something to show for it.

#
# EOF
#

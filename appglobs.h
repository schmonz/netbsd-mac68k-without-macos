/*
 * appglobs.h
 *
 * application globals
 */

/*
 * Our globals structure:
 *
 * -206(%a5) Quickdraw globals
 * 0(%a5)    Pointer to quickdraw globals
 * 4(%a5)    Point to move the pen to for a new line
 * 8(%a5)    Position after which we wrap the text line
 * 10(%a5)   Rect area which we scroll for a new line
 * 18(%a5)   Region handle (which we need for _ScrollRect)
 * 22(%a5)   Our grafport
 */

#define white -12(%a5) /* we hope, we hope */
#define	thePort	-4(%a5)
#define ourNewlinePoint 4(%a5)
#define ourLineWrapPosition 8(%a5)
#define ourScrollRect 10(%a5)
#define ourRegionHandle 18(%a5)
#define ourGrafPort 22(%a5)

size_globs_above_a5 = 22 + sizeGrafPort
size_globs_below_a5 = 206

/*
 * EOF
 */

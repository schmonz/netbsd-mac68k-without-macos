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
 */

#define white -12(%a5) /* we hope, we hope */
#define	thePort	-4(%a5)

size_globs_below_a5 = 206

/*
 * EOF
 */

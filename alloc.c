/*
 * memory allocation
 */

#include "mactraps.h"

void *alloc(unsigned int size)
{
    return NewPtr_Sys_Clear(size);
}

void free(void *ptr, unsigned int foo)
{
    DisposPtr(ptr);
}

/* EOF */

#ifndef __STRING_H__
#define __STRING_H__

#include "common.h"

void putstr(const char *str);
int strcmp(const char *a, const char *b);
void *memcpy(void *dst, const void *src, size_t len);

#endif /* __STRING_H__ */

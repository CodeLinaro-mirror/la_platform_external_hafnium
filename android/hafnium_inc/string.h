/*
 * Copyright 2020 The Hafnium Authors.
 *
 * Use of this source code is governed by a BSD-style license that can be found
 * in the LICENSE file of the main Hafnium repository or at
 * https://opensource.org/licenses/BSD-3-Clause.
 */

#pragma once

#include "hf/check.h"
#include "hf/std.h"

static inline size_t strlen(const char *s)
{
	return strnlen_s(s, RSIZE_MAX);
}

static inline size_t strnlen(const char *s, size_t maxlen)
{
	return strnlen_s(s, maxlen);
}

static inline char *strrchr(const char *s, int c)
{
	size_t cur = strnlen_s(s, RSIZE_MAX);
	CHECK(s[cur] == '\0');
	do {
		if (s[cur] == c) {
			return (char*)(&s[cur]);
		}
	} while ((cur--) > 0);
	return NULL;
}

static inline void *memcpy(void *dest, const void *src, size_t n)
{
	memcpy_s(dest, RSIZE_MAX, src, n);
	return dest;
}

static inline void *memmove(void *dest, const void *src, size_t n)
{
	memmove_s(dest, RSIZE_MAX, src, n);
	return dest;
}

static inline void *memset(void *s, int c, size_t n)
{
	memset_s(s, RSIZE_MAX, c, n);
	return s;
}

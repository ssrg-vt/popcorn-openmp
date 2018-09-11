#ifndef _COMMON_H
#define _COMMON_H

#include <sys/time.h>

#define PAGESZ 4096
#ifdef _ALIGN_LAYOUT
# define ALIGN_TO_PAGE __attribute__((aligned(PAGESZ)))
#else
# define ALIGN_TO_PAGE
#endif

#ifdef __cplusplus
extern "C" {
#endif

static inline double
stopwatch_elapsed(struct timeval *start, struct timeval *end)
{
  return (double)((end->tv_sec * 1e6 + end->tv_usec) -
         (start->tv_sec * 1e6 + start->tv_usec)) / 1e6;
}

#ifdef __cplusplus
}
#endif

#endif /* _COMMON_H */

#ifndef DRAGONFLY_LINUX_HOST_COMPAT_H
#define DRAGONFLY_LINUX_HOST_COMPAT_H

#include </usr/include/assert.h>
#include </usr/include/errno.h>
#include </usr/include/limits.h>
#include </usr/include/signal.h>
#include </usr/include/stdint.h>
#include <sys/types.h>
#include <sys/sysmacros.h>
#include <sys/vfs.h>
#include </usr/include/grp.h>
#ifndef DRAGONFLY_PASSWD_TOOL
#include </usr/include/pwd.h>
#endif

int dragonfly_setgroupent(int stayopen);
int dragonfly_setpassent(int stayopen);
int dragonfly_issetugid(void);

extern const char *dragonfly_sys_signame[NSIG];
extern const int dragonfly_sys_nsig;

int pwcache_groupdb(int (*)(int), void (*)(void),
    struct group *(*)(const char *), struct group *(*)(gid_t));
#ifndef DRAGONFLY_PASSWD_TOOL
int pwcache_userdb(int (*)(int), void (*)(void),
    struct passwd *(*)(const char *), struct passwd *(*)(uid_t));
#endif

#define setgroupent dragonfly_setgroupent
#define setpassent dragonfly_setpassent
#define issetugid dragonfly_issetugid
#define sys_signame dragonfly_sys_signame
#define sys_nsig dragonfly_sys_nsig

/* DragonFly libc uses private aliases internally. */
#define _close close
#define _fcntl fcntl
#define _fstat fstat
#define _fsync fsync
#define _open open
#define _read read
#define _sigprocmask sigprocmask
#define _unlink unlink
#define _write write

#ifndef EFTYPE
#define EFTYPE EINVAL
#endif

#ifndef REG_BASIC
#define REG_BASIC 0
#endif

#ifndef O_EXLOCK
#define O_EXLOCK 0
#endif

#ifndef O_SHLOCK
#define O_SHLOCK 0
#endif

/* DragonFly message catalogues use these fixed-width on-disk headers. */
#ifndef _NLS_MAGIC
#define _NLS_MAGIC 0xff88ff89
struct _nls_cat_hdr {
    int32_t __magic;
    int32_t __nsets;
    int32_t __mem;
    int32_t __msg_hdr_offset;
    int32_t __msg_txt_offset;
};

struct _nls_set_hdr {
    int32_t __setno;
    int32_t __nmsgs;
    int32_t __index;
};

struct _nls_msg_hdr {
    int32_t __msgno;
    int32_t __msglen;
    int32_t __offset;
};
#endif

#ifndef _CTYPE_A
#define _CTYPE_A 0x00000100L
#define _CTYPE_C 0x00000200L
#define _CTYPE_D 0x00000400L
#define _CTYPE_G 0x00000800L
#define _CTYPE_L 0x00001000L
#define _CTYPE_P 0x00002000L
#define _CTYPE_S 0x00004000L
#define _CTYPE_U 0x00008000L
#define _CTYPE_X 0x00010000L
#define _CTYPE_B 0x00020000L
#define _CTYPE_R 0x00040000L
#define _CTYPE_I 0x00080000L
#define _CTYPE_T 0x00100000L
#define _CTYPE_Q 0x00200000L
#define _CTYPE_N 0x00400000L
#define _CTYPE_SW0 0x20000000L
#define _CTYPE_SW1 0x40000000L
#define _CTYPE_SW2 0x80000000L
#define _CTYPE_SW3 0xc0000000L
#define _CTYPE_SWM 0xe0000000L
#define _CTYPE_SWS 30
#endif

#ifndef GID_MAX
#define GID_MAX UINT_MAX
#endif

#ifndef UID_MAX
#define UID_MAX UINT_MAX
#endif

#ifndef NELEM
#define NELEM(array) (sizeof(array) / sizeof((array)[0]))
#endif

#ifndef rounddown2
#define rounddown2(value, alignment) ((value) & ~((alignment) - 1))
#endif

#ifndef roundup2
#define roundup2(value, alignment) \
    (((value) + (alignment) - 1) & ~((alignment) - 1))
#endif

#ifndef bswap16
#define bswap16(value) __builtin_bswap16(value)
#endif

#ifndef bswap32
#define bswap32(value) __builtin_bswap32(value)
#endif

#ifndef bswap64
#define bswap64(value) __builtin_bswap64(value)
#endif

#ifndef ALIGN
#define ALIGN(value) \
    (((value) + sizeof(long) - 1) & ~(sizeof(long) - 1))
#endif

#ifndef MAXBSIZE
#define MAXBSIZE 65536
#endif

#ifndef MAXLOGNAME
#define MAXLOGNAME LOGIN_NAME_MAX
#endif

#ifndef MAXPHYS
#define MAXPHYS (128 * 1024)
#endif

#ifndef OFF_MAX
#define OFF_MAX ((off_t)INT64_MAX)
#endif

#ifndef QUAD_MIN
#define QUAD_MIN LLONG_MIN
#endif

#ifndef QUAD_MAX
#define QUAD_MAX LLONG_MAX
#endif

#ifndef MNT_LOCAL
#define MNT_LOCAL 0
#endif

#ifndef MNT_RDONLY
#define MNT_RDONLY MS_RDONLY
#endif

#ifndef _PATH_CP
#define _PATH_CP "/bin/cp"
#endif

#ifndef S_ISWHT
#define S_ISWHT(mode) 0
#endif

#ifndef f_iosize
#define f_iosize f_bsize
#endif

#ifndef st_atimespec
#define st_atimespec st_atim
#endif

#ifndef st_mtimespec
#define st_mtimespec st_mtim
#endif

#ifndef _DIAGASSERT
#define _DIAGASSERT(expression) assert(expression)
#endif

#ifndef __dead2
#define __dead2 __attribute__((__noreturn__))
#endif

#ifndef __DECONST
#define __DECONST(type, value) \
    ((type)(uintptr_t)(const void *)(value))
#endif

#ifndef __printflike
#define __printflike(fmtarg, firstvararg) \
    __attribute__((__format__(__printf__, fmtarg, firstvararg)))
#endif

#ifndef __pure
#define __pure __attribute__((__pure__))
#endif

#ifndef __printf0like
#define __printf0like(fmtarg, firstvararg) \
    __attribute__((__format__(__printf__, fmtarg, firstvararg)))
#endif

#ifndef __unused
#define __unused __attribute__((__unused__))
#endif

#endif

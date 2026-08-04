#ifndef DRAGONFLY_LINUX_HOST_PWD_H
#define DRAGONFLY_LINUX_HOST_PWD_H

#include <sys/types.h>
#include <time.h>

#define _PATH_PWD "/etc"
#define _PATH_PASSWD "/etc/passwd"
#define _PASSWD "passwd"
#define _PATH_MASTERPASSWD "/etc/master.passwd"
#define _MASTERPASSWD "master.passwd"
#define _PATH_MP_DB "/etc/pwd.db"
#define _MP_DB "pwd.db"
#define _PATH_SMP_DB "/etc/spwd.db"
#define _SMP_DB "spwd.db"

#define _PW_VERSION_MASK '\xF0'
#define _PW_VERSIONED(value, version) \
    ((unsigned char)(((value) & 0xCF) | ((version) << 4)))
#define _PW_KEYBYNAME '\x31'
#define _PW_KEYBYNUM '\x32'
#define _PW_KEYBYUID '\x33'
#define _PW_KEYYPENABLED '\x34'
#define _PW_KEYYPBYNUM '\x35'
#define _PWD_VERSION_KEY "\xFF" "VERSION"
#define _PWD_CURRENT_VERSION '\x04'

struct passwd {
    char *pw_name;
    char *pw_passwd;
    uid_t pw_uid;
    gid_t pw_gid;
    time_t pw_change;
    char *pw_class;
    char *pw_gecos;
    char *pw_dir;
    char *pw_shell;
    time_t pw_expire;
    int pw_fields;
};

#define _PWF(value) (1 << (value))
#define _PWF_NAME _PWF(0)
#define _PWF_PASSWD _PWF(1)
#define _PWF_UID _PWF(2)
#define _PWF_GID _PWF(3)
#define _PWF_CHANGE _PWF(4)
#define _PWF_CLASS _PWF(5)
#define _PWF_GECOS _PWF(6)
#define _PWF_DIR _PWF(7)
#define _PWF_SHELL _PWF(8)
#define _PWF_EXPIRE _PWF(9)

#endif

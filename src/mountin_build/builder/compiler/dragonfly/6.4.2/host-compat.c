#include <grp.h>
#include <pwd.h>
#include <signal.h>
#include <string.h>

#undef setgroupent
#undef setpassent

const char *dragonfly_sys_signame[NSIG];
const int dragonfly_sys_nsig = NSIG;

static void __attribute__((constructor))
dragonfly_init_signames(void)
{
    int signal_number;

    for (signal_number = 0; signal_number < NSIG; signal_number++) {
        const char *name = sigabbrev_np(signal_number);

        dragonfly_sys_signame[signal_number] =
            name == NULL ? "UNKNOWN" : name;
    }
}

int
dragonfly_setgroupent(int stayopen)
{
    (void)stayopen;
    setgrent();
    return 1;
}

int
dragonfly_setpassent(int stayopen)
{
    (void)stayopen;
    setpwent();
    return 1;
}

int
dragonfly_issetugid(void)
{
    return 0;
}

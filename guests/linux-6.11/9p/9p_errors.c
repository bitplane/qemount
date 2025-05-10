#include "9p_errors.h"
#include "9p_proto.h"
#include <errno.h>
#include <string.h>

// 9P2000 standard error strings
const char Eunknownfid[] = "unknown fid";
const char Enoauth[] = "no authentication required";
const char Ebadoffset[] = "bad offset";
const char Ebotch[] = "protocol botch";
const char Ecreatenondir[] = "create in non-directory";
const char Edupfid[] = "duplicate fid";
const char Eduptag[] = "duplicate tag";
const char Eisdir[] = "is a directory";
const char Enocreate[] = "create prohibited";
const char Enotdir[] = "not a directory";
const char Enowstat[] = "wstat prohibited";
const char Eperm[] = "permission denied";
const char Enoremove[] = "remove prohibited";
const char Enostat[] = "stat prohibited";
const char Enotfound[] = "file not found";
const char Enowrite[] = "write prohibited";
const char Enomem[] = "out of memory";
const char Enotimpl[] = "not implemented";
const char Einval[] = "invalid argument";
const char Eio[] = "i/o error";

int send_9p_error(Fcall *out, const char *err) {
    out->type = Rerror;
    strncpy(out->error.ename, err, sizeof(out->error.ename) - 1);
    out->error.ename[sizeof(out->error.ename) - 1] = '\0';
    return 0;
}

const char* map_errno_to_9p(int err) {
    switch (err) {
    case ENOENT:
        return Enotfound;
    case EPERM:
    case EACCES:
        return Eperm;
    case ENOTDIR:
        return Enotdir;
    case EISDIR:
        return Eisdir;
    case ENOMEM:
        return Enomem;
    case EINVAL:
        return Einval;
    case EIO:
    default:
        return Eio;
    }
}
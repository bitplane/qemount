#ifndef _9P_ERRORS_H
#define _9P_ERRORS_H

#include "9p_proto.h"

// 9P2000 standard error strings
extern const char Eunknownfid[];
extern const char Enoauth[];
extern const char Ebadoffset[];
extern const char Ebotch[];
extern const char Ecreatenondir[];
extern const char Edupfid[];
extern const char Eduptag[];
extern const char Eisdir[];
extern const char Enocreate[];
extern const char Enotdir[];
extern const char Enowstat[];
extern const char Eperm[];
extern const char Enoremove[];
extern const char Enostat[];
extern const char Enotfound[];
extern const char Enowrite[];
extern const char Enomem[];
extern const char Enotimpl[];
extern const char Einval[];
extern const char Eio[];

// Error helper functions
int send_9p_error(Fcall *out, const char *err);
const char* map_errno_to_9p(int err);

#endif // _9P_ERRORS_H
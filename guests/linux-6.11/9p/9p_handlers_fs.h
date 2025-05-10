#ifndef _9P_HANDLERS_FS_H
#define _9P_HANDLERS_FS_H

#include "9p_server.h"
#include "9p_proto.h"

// Filesystem operation handlers
int handle_create(Server *s, Fcall *in, Fcall *out);
int handle_remove(Server *s, Fcall *in, Fcall *out);

#endif // _9P_HANDLERS_FS_H
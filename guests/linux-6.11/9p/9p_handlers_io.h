#ifndef _9P_HANDLERS_IO_H
#define _9P_HANDLERS_IO_H

#include "9p_server.h"
#include "9p_proto.h"

// I/O operation handlers
int handle_open(Server *s, Fcall *in, Fcall *out);
int handle_read(Server *s, Fcall *in, Fcall *out);
int handle_write(Server *s, Fcall *in, Fcall *out);
int handle_stat(Server *s, Fcall *in, Fcall *out);
int handle_wstat(Server *s, Fcall *in, Fcall *out);

#endif // _9P_HANDLERS_IO_H
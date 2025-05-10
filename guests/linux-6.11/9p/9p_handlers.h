#ifndef _9P_HANDLERS_H
#define _9P_HANDLERS_H

#include "9p_server.h"
#include "9p_proto.h"

// Core protocol handlers
int handle_version(Server *s, Fcall *in, Fcall *out);
int handle_auth(Server *s, Fcall *in, Fcall *out);
int handle_attach(Server *s, Fcall *in, Fcall *out);
int handle_flush(Server *s, Fcall *in, Fcall *out);
int handle_walk(Server *s, Fcall *in, Fcall *out);
int handle_clunk(Server *s, Fcall *in, Fcall *out);

#endif // _9P_HANDLERS_H
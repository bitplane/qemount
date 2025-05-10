#ifndef _9P_SESSION_H
#define _9P_SESSION_H

#include <stdint.h>

typedef struct Session {
    uint32_t msize;         // Negotiated message size
    char version[256];      // Protocol version
    int authenticated;      // Auth status
    uint32_t next_tag;      // For tag management
} Session;

// Session management functions
Session* session_create(void);
void session_destroy(Session *s);
void session_set_msize(Session *s, uint32_t msize);
void session_set_version(Session *s, const char *version);
int session_check_version(Session *s, const char *version);

#endif // _9P_SESSION_H
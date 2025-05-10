#ifndef _9P_SERVER_H
#define _9P_SERVER_H

#include "9p_proto.h"
#include "9p_session.h"

typedef struct Server {
    char *root;          // Root directory being served
    int debug;           // Debug level
    int running;         // Server running flag
    int infd;            // Input file descriptor
    int outfd;           // Output file descriptor
    uint32_t msize;      // Maximum message size
    Session *session;    // Current session state
} Server;

// Create a new server instance
Server* server_create(const char *root, int debug);

// Destroy server instance
void server_destroy(Server *s);

// Handle a single 9P message
int server_handle_message(Server *s, Fcall *in, Fcall *out);

// Main server loop
int server_run(Server *s);

// Set server file descriptors
void server_set_fds(Server *s, int infd, int outfd);

#endif // _9P_SERVER_H
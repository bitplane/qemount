#include "9p_server.h"
#include "9p_proto.h"
#include "9p_trans.h"
#include "9p_fid.h"
#include "9p_handlers.h"
#include "9p_handlers_io.h"
#include "9p_handlers_fs.h"
#include "9p_errors.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

// Message handler function type
typedef int (*MessageHandler)(Server *s, Fcall *in, Fcall *out);

// Message dispatch table
static struct {
    uint8_t type;
    MessageHandler handler;
} handlers[] = {
    {Tversion, handle_version},
    {Tauth,    handle_auth},
    {Tattach,  handle_attach},
    {Tflush,   handle_flush},
    {Twalk,    handle_walk},
    {Topen,    handle_open},
    {Tcreate,  handle_create},
    {Tread,    handle_read},
    {Twrite,   handle_write},
    {Tclunk,   handle_clunk},
    {Tremove,  handle_remove},
    {Tstat,    handle_stat},
    {Twstat,   handle_wstat},
};

// Create a new server instance
Server* server_create(const char *root, int debug) {
    Server *s = malloc(sizeof(Server));
    if (!s) {
        return NULL;
    }
    
    s->root = strdup(root);
    if (!s->root) {
        free(s);
        return NULL;
    }
    
    s->session = session_create();
    if (!s->session) {
        free(s->root);
        free(s);
        return NULL;
    }
    
    s->debug = debug;
    s->running = 0;
    s->infd = -1;
    s->outfd = -1;
    s->msize = MAXMSG;
    
    return s;
}

// Destroy server instance
void server_destroy(Server *s) {
    if (!s) {
        return;
    }
    
    fid_destroy_all();
    session_destroy(s->session);
    free(s->root);
    free(s);
}

// Set server file descriptors
void server_set_fds(Server *s, int infd, int outfd) {
    if (!s) {
        return;
    }
    
    s->infd = infd;
    s->outfd = outfd;
}

// Handle a single 9P message
int server_handle_message(Server *s, Fcall *in, Fcall *out) {
    if (s->debug) {
        fprintf(stderr, "9P: %s tag=%u fid=%u\n", 
                msg_type_str(in->type), in->tag, in->fid);
    }
    
    // Set default response
    out->tag = in->tag;
    out->type = in->type + 1;  // Response is request + 1
    
    // Find and call handler
    for (size_t i = 0; i < sizeof(handlers)/sizeof(handlers[0]); i++) {
        if (handlers[i].type == in->type) {
            int ret = handlers[i].handler(s, in, out);
            if (s->debug && ret != 0) {
                fprintf(stderr, "Handler returned error: %d\n", ret);
            }
            return ret;
        }
    }
    
    // Unknown message type
    if (s->debug) {
        fprintf(stderr, "Unknown message type: %d\n", in->type);
    }
    return send_9p_error(out, Enotimpl);
}

// Main server loop
int server_run(Server *s) {
    if (!s || s->infd < 0 || s->outfd < 0) {
        return -1;
    }
    
    s->running = 1;
    
    if (s->debug) {
        fprintf(stderr, "Server: Starting main loop...\n");
    }
    
    while (s->running) {
        uint8_t inbuf[MAXMSG];
        uint8_t outbuf[MAXMSG];
        
        if (s->debug) {
            fprintf(stderr, "Server: Waiting for message...\n");
        }
        
        // Read a message
        int n = trans_read_msg(s->infd, inbuf, sizeof(inbuf));
        if (n < 0) {
            if (s->debug) {
                fprintf(stderr, "Server: Error reading message: %d\n", n);
            }
            // Connection error, try to recover
            usleep(100000);  // 100ms
            continue;
        }
        
        if (n == 0) {
            // Clean EOF
            if (s->debug) {
                fprintf(stderr, "Server: EOF received, waiting for reconnect...\n");
            }
            // Wait a bit for new connection
            sleep(1);
            continue;
        }
        
        if (s->debug) {
            fprintf(stderr, "Server: Received %d byte message\n", n);
        }
        
        // Unpack the message
        Fcall in, out;
        memset(&in, 0, sizeof(in));
        memset(&out, 0, sizeof(out));
        
        if (unpack_msg(inbuf, n, &in) < 0) {
            if (s->debug) {
                fprintf(stderr, "Server: Failed to unpack message\n");
            }
            // Invalid message format
            Fcall err_out;
            memset(&err_out, 0, sizeof(err_out));
            err_out.tag = NOTAG;
            send_9p_error(&err_out, Ebotch);
            int len = pack_msg(&err_out, outbuf);
            if (len > 0) {
                trans_write_msg(s->outfd, outbuf, len);
            }
            continue;
        }
        
        // Handle the message
        server_handle_message(s, &in, &out);
        
        // Pack the response
        int len = pack_msg(&out, outbuf);
        if (len < 0) {
            if (s->debug) {
                fprintf(stderr, "Server: Failed to pack response\n");
            }
            Fcall err_out;
            memset(&err_out, 0, sizeof(err_out));
            err_out.tag = in.tag;
            send_9p_error(&err_out, Eio);
            len = pack_msg(&err_out, outbuf);
            if (len > 0) {
                trans_write_msg(s->outfd, outbuf, len);
            }
            continue;
        }
        
        if (s->debug) {
            fprintf(stderr, "Server: Sending %d byte response\n", len);
        }
        
        // Send the response
        if (trans_write_msg(s->outfd, outbuf, len) < 0) {
            if (s->debug) {
                fprintf(stderr, "Server: Failed to send response\n");
            }
            // Connection might be broken, continue to allow recovery
            continue;
        }
        
        // Clean up any allocated memory in response
        if (out.type == Rread && out.read_r.data) {
            free(out.read_r.data);
        }
        if (out.type == Rstat && out.stat_r.stat) {
            free(out.stat_r.stat);
        }
    }
    
    // Cleanup on exit
    fid_destroy_all();
    
    return 0;
}
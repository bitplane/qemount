#include "server.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

/* Global variables */
IxpServer server;
char *root_path = NULL;
int debug = 0;

/* 9P server operations */
Ixp9Srv p9srv = {
    .attach = fs_attach,
    .walk = fs_walk,
    .open = fs_open,
    .read = fs_read,
    .write = fs_write,
    .create = fs_create,
    .remove = fs_remove,
    .clunk = fs_clunk,
    .stat = fs_stat,
    .wstat = fs_wstat,
    .flush = fs_flush,
    .freefid = fs_freefid,
};

/* Handle device connection directly */
static void serve_device(int fd) {
    IxpConn *conn;
    
    /* For character devices, we need to handle the connection directly */
    conn = malloc(sizeof(IxpConn));
    if(!conn) {
        fprintf(stderr, "Failed to allocate connection\n");
        return;
    }
    
    memset(conn, 0, sizeof(IxpConn));
    conn->srv = &server;
    conn->fd = fd;
    conn->aux = nil;
    conn->close = nil;
    
    /* Serve the connection */
    ixp_serve9conn(conn);
}

int main(int argc, char *argv[]) {
    char *addr = nil;
    int c;
    
    while((c = getopt(argc, argv, "dp:")) != -1) {
        switch(c) {
        case 'd':
            debug = 1;
            break;
        case 'p':
            addr = optarg;
            break;
        default:
            fprintf(stderr, "Usage: %s [-d] [-p address] <directory>\n", argv[0]);
            exit(1);
        }
    }
    
    if(optind >= argc) {
        fprintf(stderr, "Usage: %s [-d] [-p address] <directory>\n", argv[0]);
        exit(1);
    }
    
    root_path = argv[optind];
    
    /* Check if root_path exists and is a directory */
    struct stat root_st;
    if(stat(root_path, &root_st) < 0) {
        fprintf(stderr, "Cannot stat root directory %s: %s\n", root_path, strerror(errno));
        exit(1);
    }
    
    if(!S_ISDIR(root_st.st_mode)) {
        fprintf(stderr, "Root path %s is not a directory\n", root_path);
        exit(1);
    }
    
    int fd;
    
    if(!addr) {
        addr = "tcp!*!564";
    }
    
    if(debug)
        fprintf(stderr, "Starting 9P server on %s for %s\n", addr, root_path);
    
    /* Check if addr is a device file */
    struct stat st;
    if(stat(addr, &st) == 0 && S_ISCHR(st.st_mode)) {
        /* It's a character device - open it directly */
        fd = open(addr, O_RDWR);
        if(fd < 0) {
            fprintf(stderr, "Failed to open device %s: %s\n", addr, strerror(errno));
            exit(1);
        }
        if(debug)
            fprintf(stderr, "Opened device %s as fd %d\n", addr, fd);
        
        /* Initialize server */
        memset(&server, 0, sizeof(server));
        
        /* Serve the device connection directly */
        serve_device(fd);
        
        close(fd);
    } else {
        /* Try as network address */
        fd = ixp_announce(addr);
        if(fd < 0) {
            fprintf(stderr, "Failed to announce on %s: %s\n", addr, strerror(errno));
            exit(1);
        }
        
        /* Initialize server */
        memset(&server, 0, sizeof(server));
        
        /* Start listening */
        ixp_listen(&server, fd, &p9srv, ixp_serve9conn, nil);
        
        /* Run server loop */
        ixp_serverloop(&server);
    }
    
    return 0;
}
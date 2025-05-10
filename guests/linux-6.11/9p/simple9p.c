#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/stat.h>
#include "9p_server.h"

static void usage(const char *prog) {
    fprintf(stderr, "Usage: %s <root_path> [options]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -d        Enable debug output\n");
    fprintf(stderr, "  -p <dev>  Use device instead of stdin/stdout\n");
    fprintf(stderr, "  -h        Show this help\n");
    exit(1);
}

static void sighandler(int sig) {
    fprintf(stderr, "simple9p: caught signal %d\n", sig);
    if (sig == SIGSEGV || sig == SIGBUS) {
        fprintf(stderr, "simple9p: segmentation fault or bus error\n");
    }
    exit(1);
}

// Function to reopen the device when connection is lost
static int reopen_device(const char *device, int old_fd) {
    fprintf(stderr, "simple9p: attempting to reopen device %s\n", device);
    
    // Close old fd if still open
    if (old_fd >= 0) {
        close(old_fd);
    }
    
    // Wait a bit before reopening
    usleep(500000);  // 500ms
    
    // Try to reopen
    int fd = open(device, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "simple9p: failed to reopen device: %s\n", strerror(errno));
        return -1;
    }
    
    // Set non-blocking
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags >= 0) {
        fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    }
    
    fprintf(stderr, "simple9p: device reopened, fd=%d\n", fd);
    return fd;
}

int main(int argc, char **argv) {
    int opt;
    int debug = 0;
    char *device = NULL;
    char *root = NULL;
    
    // Install signal handlers
    signal(SIGSEGV, sighandler);
    signal(SIGBUS, sighandler);
    signal(SIGPIPE, SIG_IGN);
    
    // Parse command line
    while ((opt = getopt(argc, argv, "dhp:")) != -1) {
        switch (opt) {
        case 'd':
            debug = 1;
            break;
        case 'p':
            device = optarg;
            break;
        case 'h':
        default:
            usage(argv[0]);
        }
    }
    
    if (optind >= argc) {
        usage(argv[0]);
    }
    
    root = argv[optind];
    
    // Verify root directory exists
    if (access(root, F_OK) != 0) {
        fprintf(stderr, "Error: Root path '%s' does not exist\n", root);
        return 1;
    }
    
    fprintf(stderr, "simple9p: starting with root='%s'\n", root);
    
    // Main loop - keep trying to serve connections
    while (1) {
        // Create server
        Server *s = server_create(root, debug);
        if (!s) {
            fprintf(stderr, "Error: Failed to create server\n");
            return 1;
        }
        
        int fd = -1;
        
        // Set up I/O
        if (device) {
            fprintf(stderr, "simple9p: opening device '%s'\n", device);
            
            fd = open(device, O_RDWR);
            if (fd < 0) {
                fprintf(stderr, "Error: Cannot open device '%s': %s\n", 
                        device, strerror(errno));
                server_destroy(s);
                sleep(1);  // Wait before retrying
                continue;
            }
            
            // Set non-blocking
            int flags = fcntl(fd, F_GETFL, 0);
            if (flags >= 0) {
                fcntl(fd, F_SETFL, flags | O_NONBLOCK);
            }
            
            server_set_fds(s, fd, fd);
        } else {
            // Use stdin/stdout
            server_set_fds(s, 0, 1);
        }
        
        fprintf(stderr, "simple9p: starting server loop\n");
        
        // Run server
        int ret = server_run(s);
        
        fprintf(stderr, "simple9p: server loop exited with %d\n", ret);
        
        // Cleanup
        server_destroy(s);
        
        // If using a device, close and prepare to reopen
        if (device && fd >= 0) {
            close(fd);
            fprintf(stderr, "simple9p: connection lost, waiting to reconnect...\n");
            sleep(1);  // Wait before next attempt
        } else {
            // If using stdin/stdout, exit
            break;
        }
    }
    
    return 0;
}
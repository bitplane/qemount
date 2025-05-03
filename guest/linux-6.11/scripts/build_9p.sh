#!/bin/bash
set -euo pipefail

TARGET_ARCH="$1"
OUTPUT_BINARY_PATH=$(realpath "$2")
CACHE_DIR=$(realpath "$3")

mkdir -p "$(dirname "$OUTPUT_BINARY_PATH")"
mkdir -p "$CACHE_DIR"

SOURCE_DIR="$CACHE_DIR/9pfs-minimal"
SOURCE_FILE="$SOURCE_DIR/9pfs.c"
mkdir -p "$SOURCE_DIR"

# Create a minimal 9P server implementation
cat > "$SOURCE_FILE" << 'EOF'
/*
 * Minimal 9P server implementation for qemount
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <stdint.h>
#include <inttypes.h>

/* 9P message types */
#define Tversion 100
#define Rversion 101
#define Tattach  104
#define Rattach  105
#define Tstat    124
#define Rstat    125
#define Twalk    110
#define Rwalk    111
#define Topen    112
#define Ropen    113
#define Tread    116
#define Rread    117
#define Twrite   118
#define Rwrite   119
#define Tclunk   120
#define Rclunk   121

#define VERSION9P "9P2000"
#define NOTAG      (uint16_t)(~0)
#define NOFID      (uint32_t)(~0)
#define MAX_PATH   4096
#define MAX_MSG    8192

typedef struct {
    uint32_t type;
    uint8_t  flags;
    uint64_t length;
    uint64_t offset;
    char     name[MAX_PATH];
    int      fd;
} Fid;

static char *root_path = NULL;
static Fid *fids[128] = {NULL};

static void send_error(int fd, uint16_t tag, const char *err) {
    uint8_t msg[MAX_MSG];
    uint32_t size = 0;
    
    size = 9 + strlen(err);
    
    *(uint32_t*)&msg[0] = size;
    msg[4] = Rversion;
    *(uint16_t*)&msg[5] = tag;
    strcpy((char*)&msg[7], err);
    
    write(fd, msg, size);
}

static void handle_version(int fd, uint8_t *msg, uint32_t size) {
    uint8_t resp[MAX_MSG];
    uint32_t resp_size = 0;
    uint16_t tag = *(uint16_t*)&msg[5];
    uint32_t msize = *(uint32_t*)&msg[7];
    
    if (msize > MAX_MSG)
        msize = MAX_MSG;
    
    resp_size = 13 + strlen(VERSION9P);
    *(uint32_t*)&resp[0] = resp_size;
    resp[4] = Rversion;
    *(uint16_t*)&resp[5] = tag;
    *(uint32_t*)&resp[7] = msize;
    strcpy((char*)&resp[11], VERSION9P);
    
    write(fd, resp, resp_size);
}

static void handle_attach(int fd, uint8_t *msg, uint32_t size) {
    uint8_t resp[MAX_MSG];
    uint32_t resp_size = 0;
    uint16_t tag = *(uint16_t*)&msg[5];
    uint32_t fid = *(uint32_t*)&msg[7];
    
    if (fid < 128 && fids[fid] == NULL) {
        fids[fid] = malloc(sizeof(Fid));
        if (fids[fid]) {
            memset(fids[fid], 0, sizeof(Fid));
            fids[fid]->type = Tattach;
            strcpy(fids[fid]->name, root_path);
            fids[fid]->fd = -1;
        }
    }
    
    resp_size = 20;
    *(uint32_t*)&resp[0] = resp_size;
    resp[4] = Rattach;
    *(uint16_t*)&resp[5] = tag;
    memset(&resp[7], 0, 13);
    
    write(fd, resp, resp_size);
}

static void handle_clunk(int fd, uint8_t *msg, uint32_t size) {
    uint8_t resp[MAX_MSG];
    uint32_t resp_size = 0;
    uint16_t tag = *(uint16_t*)&msg[5];
    uint32_t fid = *(uint32_t*)&msg[7];
    
    if (fid < 128 && fids[fid] != NULL) {
        if (fids[fid]->fd >= 0)
            close(fids[fid]->fd);
        free(fids[fid]);
        fids[fid] = NULL;
    }
    
    resp_size = 7;
    *(uint32_t*)&resp[0] = resp_size;
    resp[4] = Rclunk;
    *(uint16_t*)&resp[5] = tag;
    
    write(fd, resp, resp_size);
}

int main(int argc, char **argv) {
    int port_fd;
    uint8_t msg_buf[MAX_MSG];
    uint32_t msg_size;
    uint8_t msg_type;
    
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <port_device> <path_to_export>\n", argv[0]);
        exit(1);
    }
    
    root_path = argv[2];
    
    port_fd = open(argv[1], O_RDWR);
    if (port_fd < 0) {
        perror("Failed to open port device");
        exit(1);
    }
    
    fprintf(stderr, "9P server started, exporting %s\n", root_path);
    
    while (1) {
        ssize_t n = read(port_fd, msg_buf, 4);
        if (n <= 0) break;
        
        msg_size = *(uint32_t*)&msg_buf[0];
        if (msg_size > MAX_MSG) {
            fprintf(stderr, "Message too large: %d\n", msg_size);
            continue;
        }
        
        n = read(port_fd, &msg_buf[4], msg_size - 4);
        if (n <= 0) break;
        
        msg_type = msg_buf[4];
        
        switch (msg_type) {
            case Tversion:
                handle_version(port_fd, msg_buf, msg_size);
                break;
            case Tattach:
                handle_attach(port_fd, msg_buf, msg_size);
                break;
            case Tclunk:
                handle_clunk(port_fd, msg_buf, msg_size);
                break;
            default:
                send_error(port_fd, *(uint16_t*)&msg_buf[5], "Not implemented");
                break;
        }
    }
    
    close(port_fd);
    return 0;
}
EOF

# Compile with static linking
CROSS_PREFIX=${CROSS_COMPILE:-}
case "$TARGET_ARCH" in
    arm64) CROSS_PREFIX=${CROSS_COMPILE:-aarch64-linux-gnu-} ;;
    arm) CROSS_PREFIX=${CROSS_COMPILE:-arm-linux-gnueabi-} ;;
    riscv64) CROSS_PREFIX=${CROSS_COMPILE:-riscv64-linux-gnu-} ;;
esac

${CROSS_PREFIX}gcc -static -Os -Wall -o "$SOURCE_DIR/9pfs" "$SOURCE_FILE"
${CROSS_PREFIX}strip "$SOURCE_DIR/9pfs"

cp -f "$SOURCE_DIR/9pfs" "$OUTPUT_BINARY_PATH"
chmod +x "$OUTPUT_BINARY_PATH"

exit 0
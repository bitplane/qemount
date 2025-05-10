#include "9p_trans.h"
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

// Read exactly n bytes
int trans_readn(int fd, void *buf, int n) {
    char *p = buf;
    int total = 0;
    
    while (total < n) {
        int r = read(fd, p + total, n - total);
        
        if (r < 0) {
            if (errno == EINTR)
                continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // Non-blocking I/O, sleep a bit
                usleep(1000);
                continue;
            }
            fprintf(stderr, "trans_readn: read error: %s\n", strerror(errno));
            return -1;
        }
        
        if (r == 0) {
            // EOF
            if (total == 0) {
                // Clean EOF
                return 0;
            }
            fprintf(stderr, "trans_readn: unexpected EOF (got %d of %d bytes)\n", total, n);
            return -1;
        }
        
        total += r;
    }
    
    return total;
}

// Write exactly n bytes
int trans_writen(int fd, const void *buf, int n) {
    const char *p = buf;
    int total = 0;
    
    while (total < n) {
        int w = write(fd, p + total, n - total);
        
        if (w < 0) {
            if (errno == EINTR)
                continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // Non-blocking I/O, sleep a bit
                usleep(1000);
                continue;
            }
            fprintf(stderr, "trans_writen: write error: %s\n", strerror(errno));
            return -1;
        }
        
        total += w;
    }
    
    return total;
}

// Read a complete 9P message
int trans_read_msg(int fd, uint8_t *buf, uint32_t maxlen) {
    // First read the 4-byte size
    uint8_t sizebuf[4];
    int n = trans_readn(fd, sizebuf, 4);
    
    if (n < 0) {
        return -1;  // Error
    }
    
    if (n == 0) {
        return 0;   // Clean EOF - no client connected
    }
    
    // Extract message size
    uint32_t size = sizebuf[0] | (sizebuf[1]<<8) | (sizebuf[2]<<16) | (sizebuf[3]<<24);
    
    if (size < 7) {
        fprintf(stderr, "trans_read_msg: invalid size %u (too small)\n", size);
        return -1;
    }
    
    if (size > maxlen) {
        fprintf(stderr, "trans_read_msg: message too large %u > %u\n", size, maxlen);
        return -1;
    }
    
    // Copy size into buffer
    memcpy(buf, sizebuf, 4);
    
    // Read the rest of the message
    n = trans_readn(fd, buf + 4, size - 4);
    if (n < 0) {
        return -1;
    }
    
    fprintf(stderr, "trans_read_msg: received %u byte message\n", size);
    
    // Debug: print first few bytes
    fprintf(stderr, "Message header: ");
    for (uint32_t i = 0; i < 10 && i < size; i++) {
        fprintf(stderr, "%02x ", buf[i]);
    }
    fprintf(stderr, "\n");
    
    return size;
}

// Write a complete 9P message
int trans_write_msg(int fd, uint8_t *buf, uint32_t len) {
    if (len < 7) {
        fprintf(stderr, "trans_write_msg: invalid length %u\n", len);
        return -1;
    }
    
    fprintf(stderr, "trans_write_msg: sending %u byte message\n", len);
    
    // Debug: print first few bytes
    fprintf(stderr, "Response header: ");
    for (uint32_t i = 0; i < 10 && i < len; i++) {
        fprintf(stderr, "%02x ", buf[i]);
    }
    fprintf(stderr, "\n");
    
    int n = trans_writen(fd, buf, len);
    if (n < 0) {
        return -1;
    }
    
    return 0;
}
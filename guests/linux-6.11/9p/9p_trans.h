#ifndef _9P_TRANS_H
#define _9P_TRANS_H

#include <stdint.h>

// Read exactly n bytes or fail
int trans_readn(int fd, void *buf, int n);

// Write exactly n bytes or fail  
int trans_writen(int fd, const void *buf, int n);

// Read a complete 9P message
// Returns message size, 0 on EOF, -1 on error
int trans_read_msg(int fd, uint8_t *buf, uint32_t maxlen);

// Write a complete 9P message
// Returns 0 on success, -1 on error
int trans_write_msg(int fd, uint8_t *buf, uint32_t len);

#endif // _9P_TRANS_H
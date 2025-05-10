#ifndef _9P_FS_H
#define _9P_FS_H

#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <time.h>
#include "9p_proto.h"

// Get file info and pack into stat buffer
int fs_stat(const char *path, uint8_t *buf, uint32_t buflen);

// Walk a path and get qid
int fs_walk(const char *path, const char *name, Qid *qid);

// Create a file or directory
int fs_create(const char *path, const char *name, uint32_t perm, uint8_t mode);

// Read from a file
int fs_read(int fd, uint64_t offset, uint32_t count, uint8_t *buf);

// Write to a file  
int fs_write(int fd, uint64_t offset, uint32_t count, const uint8_t *buf);

// Read directory entries
int fs_readdir(const char *path, DIR *dir, off_t *offset, uint8_t *buf, uint32_t count);

// Remove a file or directory
int fs_remove(const char *path);

// Stat to qid conversion
void stat2qid(const struct stat *st, Qid *qid);

// Change file attributes
int fs_wstat(const char *path, uint8_t *stat, uint16_t nstat);

#endif // _9P_FS_H
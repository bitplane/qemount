#include "9p_fs.h"
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>
#include <utime.h>

// Convert stat to qid
void stat2qid(const struct stat *st, Qid *qid) {
    qid->path = st->st_ino;
    qid->vers = st->st_mtime;
    qid->type = S_ISDIR(st->st_mode) ? QTDIR : QTFILE;
}

// Get file info and pack into stat buffer
int fs_stat(const char *path, uint8_t *buf, uint32_t buflen) {
    struct stat st;
    
    if (stat(path, &st) < 0) {
        return -1;
    }
    
    // Extract just the filename
    const char *name;
    if (strcmp(path, "/") == 0) {
        name = "/";
    } else {
        name = strrchr(path, '/');
        if (name && name[1]) {
            name++;
        } else {
            name = path;
        }
    }
    
    uint16_t size = pack_stat(buf, (char*)name, &st);
    if (size > buflen) {
        errno = ERANGE;
        return -1;
    }
    
    return size;
}

// Walk a path and get qid
int fs_walk(const char *path, const char *name, Qid *qid) {
    char *newpath = NULL;
    struct stat st;
    int ret;
    
    if (!name || !name[0]) {
        // Empty walk - just stat the current path
        ret = stat(path, &st);
    } else if (strcmp(name, "..") == 0) {
        // Walk up
        if (strcmp(path, "/") == 0) {
            // Already at root
            ret = stat("/", &st);
        } else {
            newpath = strdup(path);
            if (!newpath) {
                errno = ENOMEM;
                return -1;
            }
            
            char *slash = strrchr(newpath, '/');
            if (slash && slash != newpath) {
                *slash = '\0';
            } else {
                strcpy(newpath, "/");
            }
            
            ret = stat(newpath, &st);
        }
    } else {
        // Walk down
        size_t pathlen = strlen(path);
        size_t namelen = strlen(name);
        newpath = malloc(pathlen + 1 + namelen + 1);
        if (!newpath) {
            errno = ENOMEM;
            return -1;
        }
        
        strcpy(newpath, path);
        if (pathlen > 0 && path[pathlen-1] != '/') {
            strcat(newpath, "/");
        }
        strcat(newpath, name);
        
        ret = stat(newpath, &st);
    }
    
    if (ret == 0) {
        stat2qid(&st, qid);
    }
    
    free(newpath);
    return ret;
}

// Create a file or directory
int fs_create(const char *path, const char *name, uint32_t perm, uint8_t mode) {
    // Build full path
    size_t pathlen = strlen(path);
    size_t namelen = strlen(name);
    char *fullpath = malloc(pathlen + 1 + namelen + 1);
    if (!fullpath) {
        errno = ENOMEM;
        return -1;
    }
    
    strcpy(fullpath, path);
    if (pathlen > 0 && path[pathlen-1] != '/') {
        strcat(fullpath, "/");
    }
    strcat(fullpath, name);
    
    int ret;
    if (perm & DMDIR) {
        // Create directory
        ret = mkdir(fullpath, perm & 0777);
    } else {
        // Create file
        int flags = O_CREAT | O_EXCL;
        
        // Map 9P mode to Unix flags
        switch (mode & 3) {
        case 0:  // OREAD
            flags |= O_RDONLY;
            break;
        case 1:  // OWRITE  
            flags |= O_WRONLY;
            break;
        case 2:  // ORDWR
            flags |= O_RDWR;
            break;
        case 3:  // OEXEC
            flags |= O_RDONLY;
            break;
        }
        
        if (mode & 0x10) {  // OTRUNC
            flags |= O_TRUNC;
        }
        
        int fd = open(fullpath, flags, perm & 0777);
        if (fd >= 0) {
            close(fd);
            ret = 0;
        } else {
            ret = -1;
        }
    }
    
    free(fullpath);
    return ret;
}

// Read from a file
int fs_read(int fd, uint64_t offset, uint32_t count, uint8_t *buf) {
    off_t off = lseek(fd, offset, SEEK_SET);
    if (off < 0) {
        return -1;
    }
    
    return read(fd, buf, count);
}

// Write to a file
int fs_write(int fd, uint64_t offset, uint32_t count, const uint8_t *buf) {
    off_t off = lseek(fd, offset, SEEK_SET);
    if (off < 0) {
        return -1;
    }
    
    return write(fd, buf, count);
}

// Read directory entries
int fs_readdir(const char *path, DIR *dir, off_t *offset, uint8_t *buf, uint32_t count) {
    uint8_t *p = buf;
    uint8_t *end = buf + count;
    int n = 0;
    
    // Seek to the right position
    seekdir(dir, *offset);
    
    while (p < end) {
        struct dirent *de = readdir(dir);
        if (!de) {
            break;
        }
        
        *offset = telldir(dir);
        
        // Build full path for stat
        size_t pathlen = strlen(path);
        size_t namelen = strlen(de->d_name);
        char *fullpath = malloc(pathlen + 1 + namelen + 1);
        if (!fullpath) {
            break;
        }
        
        strcpy(fullpath, path);
        if (pathlen > 0 && path[pathlen-1] != '/') {
            strcat(fullpath, "/");
        }
        strcat(fullpath, de->d_name);
        
        // Get stat info
        struct stat st;
        if (stat(fullpath, &st) < 0) {
            free(fullpath);
            continue;
        }
        free(fullpath);
        
        // Pack the stat entry
        uint8_t statbuf[512];
        uint16_t statsize = pack_stat(statbuf, de->d_name, &st);
        
        // Check if it fits
        if (p + statsize > end) {
            // Rewind to previous position
            seekdir(dir, *offset - 1);
            *offset = telldir(dir);
            break;
        }
        
        // Copy to output buffer
        memcpy(p, statbuf, statsize);
        p += statsize;
        n++;
    }
    
    return p - buf;
}

// Remove a file or directory
int fs_remove(const char *path) {
    struct stat st;
    
    if (stat(path, &st) < 0) {
        return -1;
    }
    
    if (S_ISDIR(st.st_mode)) {
        return rmdir(path);
    } else {
        return unlink(path);
    }
}

// Change file attributes
int fs_wstat(const char *path, uint8_t *stat, uint16_t nstat) {
    // Parse the stat buffer
    // This is a simplified version - full implementation would parse
    // all fields properly
    (void)nstat;  // Suppress unused parameter warning
    
    struct utimbuf times;
    mode_t mode;
    int ret = 0;
    
    // Skip size field
    stat += 2;
    
    // Skip type and dev
    stat += 2 + 4;
    
    // Skip qid
    stat += 13;
    
    // Get mode
    mode = *(uint32_t*)stat & 0777;
    stat += 4;
    
    // Get times
    times.actime = *(uint32_t*)stat;
    stat += 4;
    times.modtime = *(uint32_t*)stat;
    
    // Apply changes
    if (chmod(path, mode) < 0) {
        ret = -1;
    }
    
    if (utime(path, &times) < 0) {
        ret = -1;
    }
    
    return ret;
}
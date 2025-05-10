#ifndef _9P_FID_H
#define _9P_FID_H

#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>

typedef struct Fid {
    uint32_t fid;
    char *path;
    int fd;                // File descriptor (-1 if not open)
    DIR *dir;              // Directory handle (NULL if not a directory)
    off_t diroffset;       // Current directory offset
    struct stat st;        // Cached stat info
    int omode;             // Open mode (-1 if not open)
    int ref;               // Reference count
    struct Fid *next;
} Fid;

// Create a new fid
Fid* fid_create(uint32_t fid, const char *path);

// Find an existing fid
Fid* fid_find(uint32_t fid);

// Destroy a fid (close files, free memory)
void fid_destroy(Fid *f);

// Destroy all fids (cleanup on disconnect)
void fid_destroy_all(void);

// Open a fid
int fid_open(Fid *f, int mode);

// Update stat info for a fid
int fid_stat(Fid *f);

// Walk to create a new fid
Fid* fid_walk(Fid *f, uint32_t newfid, char *name);

// Clone a fid
Fid* fid_clone(Fid *f, uint32_t newfid);

// Increment reference count
void fid_incref(Fid *f);

// Decrement reference count
void fid_decref(Fid *f);

#endif // _9P_FID_H
#include "9p_fid.h"
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>

static Fid *fid_list = NULL;

// Create a new fid
Fid* fid_create(uint32_t fid, const char *path) {
    // Check if fid already exists
    if (fid_find(fid) != NULL) {
        return NULL;
    }
    
    Fid *f = malloc(sizeof(Fid));
    if (!f) {
        return NULL;
    }
    
    f->fid = fid;
    f->path = strdup(path);
    if (!f->path) {
        free(f);
        return NULL;
    }
    
    f->fd = -1;
    f->dir = NULL;
    f->diroffset = 0;
    f->omode = -1;
    f->ref = 1;
    memset(&f->st, 0, sizeof(f->st));
    
    // Add to list
    f->next = fid_list;
    fid_list = f;
    
    return f;
}

// Find an existing fid
Fid* fid_find(uint32_t fid) {
    Fid *f;
    for (f = fid_list; f; f = f->next) {
        if (f->fid == fid) {
            return f;
        }
    }
    return NULL;
}

// Increment reference count
void fid_incref(Fid *f) {
    if (f) {
        f->ref++;
    }
}

// Decrement reference count
void fid_decref(Fid *f) {
    if (f && --f->ref == 0) {
        fid_destroy(f);
    }
}

// Destroy a fid
void fid_destroy(Fid *f) {
    if (!f) {
        return;
    }
    
    // Only destroy if reference count is zero
    if (f->ref > 0) {
        return;
    }
    
    // Remove from list
    Fid **p;
    for (p = &fid_list; *p; p = &(*p)->next) {
        if (*p == f) {
            *p = f->next;
            break;
        }
    }
    
    // Close file/directory if open
    if (f->fd >= 0) {
        close(f->fd);
    }
    if (f->dir) {
        closedir(f->dir);
    }
    
    // Free memory
    free(f->path);
    free(f);
}

// Destroy all fids
void fid_destroy_all(void) {
    while (fid_list) {
        Fid *next = fid_list->next;
        fid_list->ref = 0;  // Force destruction
        fid_destroy(fid_list);
        fid_list = next;
    }
}

// Open a fid
int fid_open(Fid *f, int mode) {
    if (!f || f->omode != -1) {
        return -1;  // Already open
    }
    
    int flags = 0;
    
    // Map 9P mode to Unix flags
    switch (mode & 3) {
    case 0:  // OREAD
        flags = O_RDONLY;
        break;
    case 1:  // OWRITE  
        flags = O_WRONLY;
        break;
    case 2:  // ORDWR
        flags = O_RDWR;
        break;
    case 3:  // OEXEC
        flags = O_RDONLY;
        break;
    }
    
    if (mode & 0x10) {  // OTRUNC
        flags |= O_TRUNC;
    }
    
    // Get fresh stat info
    if (fid_stat(f) < 0) {
        return -1;
    }
    
    if (S_ISDIR(f->st.st_mode)) {
        // Open directory
        if ((mode & 3) != 0) {  // Only OREAD allowed for directories
            errno = EISDIR;
            return -1;
        }
        
        f->dir = opendir(f->path);
        if (!f->dir) {
            return -1;
        }
        f->diroffset = 0;
    } else {
        // Open regular file
        f->fd = open(f->path, flags);
        if (f->fd < 0) {
            return -1;
        }
    }
    
    f->omode = mode;
    return 0;
}

// Update stat info
int fid_stat(Fid *f) {
    if (!f) {
        return -1;
    }
    
    if (stat(f->path, &f->st) < 0) {
        return -1;
    }
    
    return 0;
}

// Walk to create a new fid
Fid* fid_walk(Fid *f, uint32_t newfid, char *name) {
    if (!f) {
        return NULL;
    }
    
    char *newpath;
    
    if (name && strcmp(name, "..") == 0) {
        // Walk up
        if (strcmp(f->path, "/") == 0) {
            // Already at root
            newpath = strdup("/");
        } else {
            newpath = strdup(f->path);
            if (!newpath) {
                return NULL;
            }
            
            char *slash = strrchr(newpath, '/');
            if (slash && slash != newpath) {
                *slash = '\0';
            } else {
                strcpy(newpath, "/");
            }
        }
    } else if (name && name[0]) {
        // Walk down
        size_t len = strlen(f->path);
        size_t namelen = strlen(name);
        newpath = malloc(len + 1 + namelen + 1);
        if (newpath) {
            strcpy(newpath, f->path);
            if (len > 0 && f->path[len-1] != '/') {
                strcat(newpath, "/");
            }
            strcat(newpath, name);
        }
    } else {
        // Clone
        newpath = strdup(f->path);
    }
    
    if (!newpath) {
        return NULL;
    }
    
    // Verify the path exists
    struct stat st;
    if (stat(newpath, &st) < 0) {
        free(newpath);
        return NULL;
    }
    
    // Create new fid
    Fid *newfid_obj = fid_create(newfid, newpath);
    free(newpath);
    
    if (newfid_obj) {
        newfid_obj->st = st;
    }
    
    return newfid_obj;
}

// Clone a fid
Fid* fid_clone(Fid *f, uint32_t newfid) {
    return fid_walk(f, newfid, NULL);
}
#include "server.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <libgen.h>

void fs_read(Ixp9Req *r) {
    char *path = r->fid->aux;
    char fullpath[PATH_MAX];
    struct stat st;
    
    if(!getfullpath(path, fullpath, sizeof(fullpath))) {
        ixp_respond(r, "invalid path");
        return;
    }
    
    if(lstat(fullpath, &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    if(S_ISDIR(st.st_mode)) {
        read_directory(r, fullpath);
    } else if(S_ISLNK(st.st_mode)) {
        read_symlink(r, fullpath);
    } else {
        read_file(r, fullpath);
    }
}

void fs_write(Ixp9Req *r) {
    char *path = r->fid->aux;
    char fullpath[PATH_MAX];
    int fd;
    
    if(!getfullpath(path, fullpath, sizeof(fullpath))) {
        ixp_respond(r, "invalid path");
        return;
    }
    
    fd = open(fullpath, O_WRONLY);
    if(fd < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    lseek(fd, r->ifcall.twrite.offset, SEEK_SET);
    int n = write(fd, r->ifcall.twrite.data, r->ifcall.twrite.count);
    close(fd);
    
    if(n < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    r->ofcall.rwrite.count = n;
    ixp_respond(r, nil);
}

void fs_create(Ixp9Req *r) {
    char *path = r->fid->aux;
    char newpath[PATH_MAX];
    char fullpath[PATH_MAX];
    struct stat st;
    int fd;
    mode_t mode;
    char *aux;
    
    /* Build the new path */
    strncpy(newpath, path, PATH_MAX-1);
    newpath[PATH_MAX-1] = '\0';
    
    if(strcmp(newpath, "/") != 0) {
        if(safe_strcat(newpath, "/", PATH_MAX) < 0) {
            ixp_respond(r, "path too long");
            return;
        }
    }
    
    if(safe_strcat(newpath, r->ifcall.tcreate.name, PATH_MAX) < 0) {
        ixp_respond(r, "path too long");
        return;
    }
    
    if(!getfullpath(newpath, fullpath, sizeof(fullpath))) {
        ixp_respond(r, "invalid path");
        return;
    }
    
    /* Convert 9P permissions to Unix permissions */
    mode = r->ifcall.tcreate.perm & 0777;
    
    if(r->ifcall.tcreate.perm & P9_DMDIR) {
        /* Create directory */
        if(mkdir(fullpath, mode) < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
    } else {
        /* Create file */
        fd = open(fullpath, O_CREAT | O_EXCL | O_RDWR, mode);
        if(fd < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
        close(fd);
    }
    
    /* Stat the new file/directory */
    if(lstat(fullpath, &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    /* Update the fid */
    aux = strdup(newpath);
    if(!aux) {
        ixp_respond(r, "out of memory");
        return;
    }
    
    free(r->fid->aux);
    r->fid->aux = aux;
    
    r->fid->qid.type = S_ISDIR(st.st_mode) ? P9_QTDIR : P9_QTFILE;
    r->fid->qid.path = st.st_ino;
    r->fid->qid.version = st.st_mtime;
    
    r->ofcall.rcreate.qid = r->fid->qid;
    r->ofcall.rcreate.iounit = 0;
    ixp_respond(r, nil);
}

void fs_remove(Ixp9Req *r) {
    char *path = r->fid->aux;
    char fullpath[PATH_MAX];
    struct stat st;
    
    if(!getfullpath(path, fullpath, sizeof(fullpath))) {
        ixp_respond(r, "invalid path");
        return;
    }
    
    if(lstat(fullpath, &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    if(S_ISDIR(st.st_mode)) {
        if(rmdir(fullpath) < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
    } else {
        if(unlink(fullpath) < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
    }
    
    ixp_respond(r, nil);
}
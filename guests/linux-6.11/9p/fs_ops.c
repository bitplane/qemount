#include "server.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

/* Real file operations */
void fs_attach(Ixp9Req *r) {
    char *aux = strdup("/");
    if(!aux) {
        ixp_respond(r, "out of memory");
        return;
    }
    
    r->fid->qid.type = P9_QTDIR;
    r->fid->qid.path = 0;
    r->fid->aux = aux;
    r->ofcall.rattach.qid = r->fid->qid;
    ixp_respond(r, nil);
}

void fs_walk(Ixp9Req *r) {
    char *path = r->fid->aux;
    char newpath[PATH_MAX];
    char fullpath[PATH_MAX];
    struct stat st;
    int i;
    char *aux = NULL;

    if(r->ifcall.twalk.nwname == 0) {
        aux = strdup(path);
        if(!aux) {
            ixp_respond(r, "out of memory");
            return;
        }
        r->newfid->aux = aux;
        r->newfid->qid = r->fid->qid;
        ixp_respond(r, nil);
        return;
    }

    strncpy(newpath, path, PATH_MAX-1);
    newpath[PATH_MAX-1] = '\0';
    
    for(i = 0; i < r->ifcall.twalk.nwname; i++) {
        if(strcmp(newpath, "/") != 0) {
            if(safe_strcat(newpath, "/", PATH_MAX) < 0) {
                ixp_respond(r, "path too long");
                return;
            }
        }
        
        if(safe_strcat(newpath, r->ifcall.twalk.wname[i], PATH_MAX) < 0) {
            ixp_respond(r, "path too long");
            return;
        }
        
        if(!getfullpath(newpath, fullpath, sizeof(fullpath))) {
            ixp_respond(r, "invalid path");
            return;
        }
        
        if(lstat(fullpath, &st) < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
        
        r->ofcall.rwalk.wqid[i].type = P9_QTFILE;
        if(S_ISDIR(st.st_mode))
            r->ofcall.rwalk.wqid[i].type = P9_QTDIR;
        else if(S_ISLNK(st.st_mode))
            r->ofcall.rwalk.wqid[i].type = P9_QTSYMLINK;
        
        r->ofcall.rwalk.wqid[i].path = st.st_ino;
        r->ofcall.rwalk.wqid[i].version = st.st_mtime;
    }

    r->ofcall.rwalk.nwqid = i;
    r->newfid->qid = r->ofcall.rwalk.wqid[i-1];
    
    aux = strdup(newpath);
    if(!aux) {
        ixp_respond(r, "out of memory");
        return;
    }
    r->newfid->aux = aux;
    ixp_respond(r, nil);
}

void fs_open(Ixp9Req *r) {
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
    
    r->fid->qid.type = P9_QTFILE;
    if(S_ISDIR(st.st_mode))
        r->fid->qid.type = P9_QTDIR;
    else if(S_ISLNK(st.st_mode))
        r->fid->qid.type = P9_QTSYMLINK;
    
    r->fid->qid.path = st.st_ino;
    r->fid->qid.version = st.st_mtime;
    r->ofcall.ropen.qid = r->fid->qid;
    ixp_respond(r, nil);
}

void fs_clunk(Ixp9Req *r) {
    ixp_respond(r, nil);
}

void fs_flush(Ixp9Req *r) {
    ixp_respond(r, nil);
}

void fs_freefid(IxpFid *f) {
    if(f && f->aux) {
        free(f->aux);
        f->aux = NULL;
    }
}
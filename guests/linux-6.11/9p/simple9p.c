/* Simple 9P server using libixp - serves real files */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <dirent.h>
#include <libgen.h>
#include <signal.h>
#include <ixp.h>

/* libixp uses nil instead of NULL */
#define nil NULL

static IxpServer server;
static char *root_path = NULL;
static int debug = 0;

/* Helper to build full path */
static char *getfullpath(const char *path) {
    static char fullpath[PATH_MAX];
    snprintf(fullpath, sizeof(fullpath), "%s%s", root_path, path);
    return fullpath;
}

/* Real file operations */
static void fs_attach(Ixp9Req *r) {
    r->fid->qid.type = P9_QTDIR;
    r->fid->qid.path = 0;
    r->fid->aux = strdup("/");
    r->ofcall.rattach.qid = r->fid->qid;
    ixp_respond(r, nil);
}

static void fs_walk(Ixp9Req *r) {
    char *path = r->fid->aux;
    char newpath[PATH_MAX];
    struct stat st;
    int i;

    if(r->ifcall.twalk.nwname == 0) {
        r->newfid->aux = strdup(path);
        r->newfid->qid = r->fid->qid;
        ixp_respond(r, nil);
        return;
    }

    strcpy(newpath, path);
    for(i = 0; i < r->ifcall.twalk.nwname; i++) {
        if(strcmp(newpath, "/") != 0)
            strcat(newpath, "/");
        strcat(newpath, r->ifcall.twalk.wname[i]);
        
        if(stat(getfullpath(newpath), &st) < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
        
        r->ofcall.rwalk.wqid[i].type = S_ISDIR(st.st_mode) ? P9_QTDIR : P9_QTFILE;
        r->ofcall.rwalk.wqid[i].path = st.st_ino;
        r->ofcall.rwalk.wqid[i].version = st.st_mtime;
    }

    r->ofcall.rwalk.nwqid = i;
    r->newfid->qid = r->ofcall.rwalk.wqid[i-1];
    r->newfid->aux = strdup(newpath);
    ixp_respond(r, nil);
}

static void fs_open(Ixp9Req *r) {
    char *path = r->fid->aux;
    struct stat st;
    
    if(stat(getfullpath(path), &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    r->fid->qid.type = S_ISDIR(st.st_mode) ? P9_QTDIR : P9_QTFILE;
    r->fid->qid.path = st.st_ino;
    r->fid->qid.version = st.st_mtime;
    r->ofcall.ropen.qid = r->fid->qid;
    ixp_respond(r, nil);
}

static void fs_read(Ixp9Req *r) {
    char *path = r->fid->aux;
    char *fullpath = getfullpath(path);
    struct stat st;
    
    if(stat(fullpath, &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    if(S_ISDIR(st.st_mode)) {
        DIR *dir = opendir(fullpath);
        struct dirent *de;
        IxpMsg m;
        char *buf;
        
        if(!dir) {
            ixp_respond(r, strerror(errno));
            return;
        }
        
        buf = malloc(r->ifcall.tread.count);
        m = ixp_message(buf, r->ifcall.tread.count, MsgPack);
        
        seekdir(dir, r->ifcall.tread.offset);
        
        while((de = readdir(dir)) && m.pos - buf < r->ifcall.tread.count - 1) {
            IxpStat s;
            struct stat st2;
            char childpath[PATH_MAX];
            
            snprintf(childpath, sizeof(childpath), "%s/%s", fullpath, de->d_name);
            if(stat(childpath, &st2) < 0)
                continue;
                
            s.type = 0;
            s.dev = 0;
            s.qid.type = S_ISDIR(st2.st_mode) ? P9_QTDIR : P9_QTFILE;
            s.qid.path = st2.st_ino;
            s.qid.version = st2.st_mtime;
            s.mode = st2.st_mode & 0777;
            if(S_ISDIR(st2.st_mode))
                s.mode |= P9_DMDIR;
            s.atime = st2.st_atime;
            s.mtime = st2.st_mtime;
            s.length = st2.st_size;
            s.name = de->d_name;
            s.uid = getenv("USER");
            if(!s.uid) s.uid = "none";
            s.gid = s.uid;
            s.muid = s.uid;
            
            ixp_pstat(&m, &s);
        }
        
        closedir(dir);
        r->ofcall.rread.count = m.pos - buf;
        r->ofcall.rread.data = buf;
        ixp_respond(r, nil);
        free(buf);
    } else {
        int fd = open(fullpath, O_RDONLY);
        if(fd < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
        
        char *buf = malloc(r->ifcall.tread.count);
        lseek(fd, r->ifcall.tread.offset, SEEK_SET);
        int n = read(fd, buf, r->ifcall.tread.count);
        close(fd);
        
        if(n < 0) {
            free(buf);
            ixp_respond(r, strerror(errno));
            return;
        }
        
        r->ofcall.rread.count = n;
        r->ofcall.rread.data = buf;
        ixp_respond(r, nil);
        free(buf);
    }
}

static void fs_write(Ixp9Req *r) {
    ixp_respond(r, "read only filesystem");
}

static void fs_clunk(Ixp9Req *r) {
    free(r->fid->aux);
    ixp_respond(r, nil);
}

static void fs_stat(Ixp9Req *r) {
    char *path = r->fid->aux;
    struct stat st;
    IxpStat s;
    IxpMsg m;
    uint16_t size;
    
    if(stat(getfullpath(path), &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    s.type = 0;
    s.dev = 0;
    s.qid = r->fid->qid;
    s.mode = st.st_mode & 0777;
    if(S_ISDIR(st.st_mode))
        s.mode |= P9_DMDIR;
    s.atime = st.st_atime;
    s.mtime = st.st_mtime;
    s.length = st.st_size;
    s.name = strrchr(path, '/');
    if(s.name && s.name[1])
        s.name++;
    else
        s.name = path;
    if(strcmp(path, "/") == 0)
        s.name = "/";
    s.uid = getenv("USER");
    if(!s.uid) s.uid = "none";
    s.gid = s.uid;
    s.muid = s.uid;
    
    size = ixp_sizeof_stat(&s);
    r->ofcall.rstat.nstat = size;
    r->ofcall.rstat.stat = malloc(size);
    
    m = ixp_message(r->ofcall.rstat.stat, size, MsgPack);
    ixp_pstat(&m, &s);
    
    ixp_respond(r, nil);
}

static void fs_flush(Ixp9Req *r) {
    ixp_respond(r, nil);
}

static void fs_freefid(IxpFid *f) {
    free(f->aux);
}

Ixp9Srv p9srv = {
    .attach = fs_attach,
    .walk = fs_walk,
    .open = fs_open,
    .read = fs_read,
    .write = fs_write,
    .clunk = fs_clunk,
    .stat = fs_stat,
    .flush = fs_flush,
    .freefid = fs_freefid,
};

int main(int argc, char *argv[]) {
    char *addr = nil;
    int c;
    
    while((c = getopt(argc, argv, "dp:")) != -1) {
        switch(c) {
        case 'd':
            debug = 1;
            break;
        case 'p':
            addr = optarg;
            break;
        default:
            fprintf(stderr, "Usage: %s [-d] [-p address] <directory>\n", argv[0]);
            exit(1);
        }
    }
    
    if(optind >= argc) {
        fprintf(stderr, "Usage: %s [-d] [-p address] <directory>\n", argv[0]);
        exit(1);
    }
    
    root_path = argv[optind];
    
    if(!addr)
        addr = "tcp!*!564";
    
    if(debug)
        fprintf(stderr, "Starting 9P server on %s for %s\n", addr, root_path);
    
    /* Create socket */
    int fd = ixp_announce(addr);
    if(fd < 0) {
        fprintf(stderr, "Failed to announce on %s: %s\n", addr, strerror(errno));
        exit(1);
    }
    
    /* Initialize server */
    memset(&server, 0, sizeof(server));
    
    /* Start listening */
    ixp_listen(&server, fd, &p9srv, ixp_serve9conn, nil);
    
    /* Run server loop */
    ixp_serverloop(&server);
    
    return 0;
}
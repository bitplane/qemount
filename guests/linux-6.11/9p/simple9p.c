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
#include <limits.h>
#include <ixp.h>

/* libixp uses nil instead of NULL */
#define nil NULL

static IxpServer server;
static char *root_path = NULL;
static int debug = 0;

/* Clean a path - remove . and .. components, duplicate slashes, etc. */
static void cleanname(char *name) {
    char *p, *q, *dotdot;
    int rooted;

    if(name[0] == '\0')
        return;

    rooted = (name[0] == '/');
    
    /* invariants:
     *  p points at beginning of path element we're considering.
     *  q points just past the last path element we wrote (no slash).
     *  dotdot points just past the point where .. cannot backtrack
     *    any further (no slash).
     */
    p = q = dotdot = name + rooted;
    while(*p) {
        if(p[0] == '/') {
            p++;
        } else if(p[0] == '.' && (p[1] == '\0' || p[1] == '/')) {
            p++;
        } else if(p[0] == '.' && p[1] == '.' && (p[2] == '\0' || p[2] == '/')) {
            p += 2;
            if(q > dotdot) {
                /* can backtrack */
                while(--q > dotdot && q[-1] != '/')
                    ;
            } else if(!rooted) {
                /* /.. is / but ./../ is .. */
                if(q != name)
                    *q++ = '/';
                *q++ = '.';
                *q++ = '.';
                dotdot = q;
            }
        } else {
            /* real path element */
            if(q != name + rooted)
                *q++ = '/';
            while((*q = *p) != '\0' && *q != '/')
                p++, q++;
        }
    }
    
    if(q == name) {
        if(rooted) {
            *q++ = '/';
        } else {
            *q++ = '.';
        }
    }
    *q = '\0';
}

/* Helper to build full path - now thread-safe and secure */
static char *getfullpath(const char *path, char *buffer, size_t bufsize) {
    char cleaned[PATH_MAX];
    
    if(!path || !buffer || bufsize < PATH_MAX) {
        return NULL;
    }
    
    /* Copy and clean the path */
    strncpy(cleaned, path, PATH_MAX-1);
    cleaned[PATH_MAX-1] = '\0';
    cleanname(cleaned);
    
    /* Check for directory traversal attempts */
    if(strstr(cleaned, "../") != NULL) {
        ixp_werrstr("Invalid path: directory traversal attempt");
        return NULL;
    }
    
    /* Build the full path */
    if(snprintf(buffer, bufsize, "%s%s", root_path, cleaned) >= bufsize) {
        ixp_werrstr("Path too long");
        return NULL;
    }
    
    return buffer;
}

/* Safe string operations */
static int safe_strcat(char *dst, const char *src, size_t dstsize) {
    size_t dstlen = strlen(dst);
    size_t srclen = strlen(src);
    
    if(dstlen + srclen >= dstsize) {
        return -1;
    }
    
    strcat(dst, src);
    return 0;
}

/* Real file operations */
static void fs_attach(Ixp9Req *r) {
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

static void fs_walk(Ixp9Req *r) {
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

static void fs_open(Ixp9Req *r) {
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

static void fs_read(Ixp9Req *r) {
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
        DIR *dir = opendir(fullpath);
        struct dirent *de;
        IxpMsg m;
        char *buf = NULL;
        uint64_t offset = r->ifcall.tread.offset;
        uint64_t pos = 0;
        
        if(!dir) {
            ixp_respond(r, strerror(errno));
            return;
        }
        
        buf = malloc(r->ifcall.tread.count);
        if(!buf) {
            closedir(dir);
            ixp_respond(r, "out of memory");
            return;
        }
        
        m = ixp_message(buf, r->ifcall.tread.count, MsgPack);
        
        /* Read directory entries, skipping until we reach the requested offset */
        while((de = readdir(dir))) {
            IxpStat s;
            struct stat st2;
            char childpath[PATH_MAX];
            char statbuf[512];
            IxpMsg sm;
            uint16_t slen;
            
            if(snprintf(childpath, sizeof(childpath), "%s/%s", fullpath, de->d_name) >= sizeof(childpath))
                continue;
                
            if(lstat(childpath, &st2) < 0)
                continue;
            
            /* Build stat structure */
            s.type = 0;
            s.dev = 0;
            s.qid.type = P9_QTFILE;
            if(S_ISDIR(st2.st_mode))
                s.qid.type = P9_QTDIR;
            else if(S_ISLNK(st2.st_mode))
                s.qid.type = P9_QTSYMLINK;
                
            s.qid.path = st2.st_ino;
            s.qid.version = st2.st_mtime;
            s.mode = st2.st_mode & 0777;
            if(S_ISDIR(st2.st_mode))
                s.mode |= P9_DMDIR;
            else if(S_ISLNK(st2.st_mode))
                s.mode |= P9_DMSYMLINK;
                
            s.atime = st2.st_atime;
            s.mtime = st2.st_mtime;
            s.length = st2.st_size;
            s.name = de->d_name;
            s.uid = getenv("USER");
            if(!s.uid) s.uid = "none";
            s.gid = s.uid;
            s.muid = s.uid;
            
            /* Calculate size of this stat entry */
            slen = ixp_sizeof_stat(&s);
            
            /* Skip entries until we reach the offset */
            if(pos + slen <= offset) {
                pos += slen;
                continue;
            }
            
            /* If this entry won't fit in the buffer, stop */
            if(m.pos - buf + slen > r->ifcall.tread.count)
                break;
            
            /* Add this entry to the result */
            ixp_pstat(&m, &s);
            pos += slen;
        }
        
        closedir(dir);
        r->ofcall.rread.count = m.pos - buf;
        r->ofcall.rread.data = buf;
        ixp_respond(r, nil);
        /* buf is now owned by libixp */
    } else if(S_ISLNK(st.st_mode)) {
        /* For symbolic links, read the link target */
        char *buf = malloc(r->ifcall.tread.count);
        int n;
        
        if(!buf) {
            ixp_respond(r, "out of memory");
            return;
        }
        
        n = readlink(fullpath, buf, r->ifcall.tread.count - 1);
        if(n < 0) {
            free(buf);
            ixp_respond(r, strerror(errno));
            return;
        }
        
        /* readlink doesn't null-terminate */
        buf[n] = '\0';
        
        /* Respect the offset */
        if(r->ifcall.tread.offset >= n) {
            r->ofcall.rread.count = 0;
            r->ofcall.rread.data = buf;
        } else {
            int len = n - r->ifcall.tread.offset;
            if(len > r->ifcall.tread.count)
                len = r->ifcall.tread.count;
            memmove(buf, buf + r->ifcall.tread.offset, len);
            r->ofcall.rread.count = len;
            r->ofcall.rread.data = buf;
        }
        
        ixp_respond(r, nil);
        /* buf is now owned by libixp */
    } else {
        int fd = open(fullpath, O_RDONLY);
        char *buf = NULL;
        
        if(fd < 0) {
            ixp_respond(r, strerror(errno));
            return;
        }
        
        buf = malloc(r->ifcall.tread.count);
        if(!buf) {
            close(fd);
            ixp_respond(r, "out of memory");
            return;
        }
        
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
        /* buf is now owned by libixp */
    }
}

static void fs_write(Ixp9Req *r) {
    ixp_respond(r, "read only filesystem");
}

static void fs_clunk(Ixp9Req *r) {
    ixp_respond(r, nil);
}

static void fs_stat(Ixp9Req *r) {
    char *path = r->fid->aux;
    char fullpath[PATH_MAX];
    struct stat st;
    IxpStat s;
    IxpMsg m;
    uint16_t size;
    
    if(!getfullpath(path, fullpath, sizeof(fullpath))) {
        ixp_respond(r, "invalid path");
        return;
    }
    
    if(lstat(fullpath, &st) < 0) {
        ixp_respond(r, strerror(errno));
        return;
    }
    
    s.type = 0;
    s.dev = 0;
    s.qid = r->fid->qid;
    s.mode = st.st_mode & 0777;
    if(S_ISDIR(st.st_mode))
        s.mode |= P9_DMDIR;
    else if(S_ISLNK(st.st_mode))
        s.mode |= P9_DMSYMLINK;
        
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
    if(!r->ofcall.rstat.stat) {
        ixp_respond(r, "out of memory");
        return;
    }
    
    m = ixp_message(r->ofcall.rstat.stat, size, MsgPack);
    ixp_pstat(&m, &s);
    
    ixp_respond(r, nil);
    /* stat buffer is now owned by libixp */
}

static void fs_flush(Ixp9Req *r) {
    ixp_respond(r, nil);
}

static void fs_freefid(IxpFid *f) {
    if(f && f->aux) {
        free(f->aux);
        f->aux = NULL;
    }
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

/* Handle device connection directly */
static void serve_device(int fd) {
    IxpConn *conn;
    
    /* For character devices, we need to handle the connection directly */
    conn = malloc(sizeof(IxpConn));
    if(!conn) {
        fprintf(stderr, "Failed to allocate connection\n");
        return;
    }
    
    memset(conn, 0, sizeof(IxpConn));
    conn->srv = &server;
    conn->fd = fd;
    conn->aux = nil;
    conn->close = nil;
    
    /* Serve the connection */
    ixp_serve9conn(conn);
}

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
    
    /* Check if root_path exists and is a directory */
    struct stat root_st;
    if(stat(root_path, &root_st) < 0) {
        fprintf(stderr, "Cannot stat root directory %s: %s\n", root_path, strerror(errno));
        exit(1);
    }
    
    if(!S_ISDIR(root_st.st_mode)) {
        fprintf(stderr, "Root path %s is not a directory\n", root_path);
        exit(1);
    }
    
    int fd;
    
    if(!addr) {
        addr = "tcp!*!564";
    }
    
    if(debug)
        fprintf(stderr, "Starting 9P server on %s for %s\n", addr, root_path);
    
    /* Check if addr is a device file */
    struct stat st;
    if(stat(addr, &st) == 0 && S_ISCHR(st.st_mode)) {
        /* It's a character device - open it directly */
        fd = open(addr, O_RDWR);
        if(fd < 0) {
            fprintf(stderr, "Failed to open device %s: %s\n", addr, strerror(errno));
            exit(1);
        }
        if(debug)
            fprintf(stderr, "Opened device %s as fd %d\n", addr, fd);
        
        /* Initialize server */
        memset(&server, 0, sizeof(server));
        
        /* Serve the device connection directly */
        serve_device(fd);
        
        close(fd);
    } else {
        /* Try as network address */
        fd = ixp_announce(addr);
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
    }
    
    return 0;
}
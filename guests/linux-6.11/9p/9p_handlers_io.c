#include "9p_handlers_io.h"
#include "9p_fid.h"
#include "9p_fs.h"
#include "9p_errors.h"
#include <sys/stat.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

int handle_open(Server *s, Fcall *in, Fcall *out) {
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    if (fid_open(f, in->open.mode) < 0) {
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    stat2qid(&f->st, &out->open_r.qid);
    out->open_r.iounit = s->session->msize - IOHDRSZ;
    return 0;
}

int handle_read(Server *s, Fcall *in, Fcall *out) {
    (void)s;
    
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    if (f->omode == -1) {
        return send_9p_error(out, Ebotch);
    }
    
    // Check read permission
    if ((f->omode & 3) == OWRITE) {
        return send_9p_error(out, Eperm);
    }
    
    out->read_r.data = malloc(in->read.count);
    if (!out->read_r.data) {
        return send_9p_error(out, Enomem);
    }
    
    int n;
    if (S_ISDIR(f->st.st_mode)) {
        n = fs_readdir(f->path, f->dir, &f->diroffset, 
                       out->read_r.data, in->read.count);
    } else {
        n = fs_read(f->fd, in->read.offset, in->read.count, 
                    out->read_r.data);
    }
    
    if (n < 0) {
        free(out->read_r.data);
        out->read_r.data = NULL;
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    out->read_r.count = n;
    return 0;
}

int handle_write(Server *s, Fcall *in, Fcall *out) {
    (void)s;
    
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    if (f->omode == -1) {
        return send_9p_error(out, Ebotch);
    }
    
    // Check write permission
    if ((f->omode & 3) == OREAD) {
        return send_9p_error(out, Eperm);
    }
    
    if (S_ISDIR(f->st.st_mode)) {
        return send_9p_error(out, Eisdir);
    }
    
    int n = fs_write(f->fd, in->write.offset, in->write.count, 
                     in->write.data);
    if (n < 0) {
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    out->write_r.count = n;
    return 0;
}

int handle_stat(Server *s, Fcall *in, Fcall *out) {
    (void)s;
    
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    // Get fresh stat
    if (fid_stat(f) < 0) {
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    // For stat, we need to use the basename of the path
    const char *name;
    if (strcmp(f->path, "/") == 0) {
        name = "/";
    } else {
        name = strrchr(f->path, '/');
        if (name && name[1]) {
            name++;
        } else {
            name = f->path;
        }
    }
    
    // Pack stat
    uint8_t statbuf[512];
    uint16_t statsize = pack_stat(statbuf, (char*)name, &f->st);
    
    out->stat_r.nstat = statsize;
    out->stat_r.stat = malloc(statsize);
    if (!out->stat_r.stat) {
        return send_9p_error(out, Enomem);
    }
    memcpy(out->stat_r.stat, statbuf, statsize);
    return 0;
}

int handle_wstat(Server *s, Fcall *in, Fcall *out) {
    (void)s;
    
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    if (fs_wstat(f->path, in->wstat.stat, in->wstat.nstat) < 0) {
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    // Update cached stat
    fid_stat(f);
    return 0;
}
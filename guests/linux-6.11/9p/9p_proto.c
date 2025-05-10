#include "9p_proto.h"
#include <stdio.h>
#include <sys/stat.h>

// Low-level packing functions
void put1(uint8_t *p, uint8_t v) {
    p[0] = v;
}

void put2(uint8_t *p, uint16_t v) {
    p[0] = v;
    p[1] = v >> 8;
}

void put4(uint8_t *p, uint32_t v) {
    p[0] = v;
    p[1] = v >> 8;
    p[2] = v >> 16;
    p[3] = v >> 24;
}

void put8(uint8_t *p, uint64_t v) {
    put4(p, v);
    put4(p+4, v >> 32);
}

void pqid(uint8_t *p, Qid *q) {
    put1(p, q->type);
    put4(p+1, q->vers);
    put8(p+5, q->path);
}

void pstr(uint8_t *p, char *s, uint16_t max) {
    uint16_t n = strlen(s);
    if (n > max) n = max;
    put2(p, n);
    memcpy(p+2, s, n);
}

// Low-level unpacking functions
uint8_t get1(uint8_t *p) {
    return p[0];
}

uint16_t get2(uint8_t *p) {
    return p[0] | (p[1]<<8);
}

uint32_t get4(uint8_t *p) {
    return p[0] | (p[1]<<8) | (p[2]<<16) | (p[3]<<24);
}

uint64_t get8(uint8_t *p) {
    return get4(p) | ((uint64_t)get4(p+4) << 32);
}

void gqid(uint8_t *p, Qid *q) {
    q->type = get1(p);
    q->vers = get4(p+1);
    q->path = get8(p+5);
}

char* gstr(uint8_t *p, char *buf, uint16_t max) {
    uint16_t n = get2(p);
    if (n > max-1) n = max-1;
    memcpy(buf, p+2, n);
    buf[n] = '\0';
    return buf;
}

// Calculate message size
uint32_t size_msg(Fcall *fc) {
    uint32_t n = 4+1+2;  // size[4] type[1] tag[2]
    
    switch(fc->type) {
    case Tversion:
    case Rversion:
        n += 4 + 2 + strlen(fc->version.version);
        break;
    case Tattach:
        n += 4 + 4 + 2 + strlen(fc->attach.uname) + 2 + strlen(fc->attach.aname);
        break;
    case Rattach:
        n += 13;  // qid
        break;
    case Rerror:
        n += 2 + strlen(fc->error.ename);
        break;
    case Tflush:
        n += 2;  // oldtag
        break;
    case Rflush:
        break;
    case Twalk:
        n += 4 + 4 + 2;  // fid, newfid, nwname
        for (int i = 0; i < fc->walk.nwname; i++) {
            n += 2 + strlen(fc->walk.wname[i]);
        }
        break;
    case Rwalk:
        n += 2 + 13 * fc->walk_r.nwqid;  // nwqid + qids
        break;
    case Topen:
        n += 4 + 1;  // fid + mode
        break;
    case Ropen:
        n += 13 + 4;  // qid + iounit
        break;
    case Tcreate:
        n += 4 + 2 + strlen(fc->create.name) + 4 + 1;  // fid + name + perm + mode
        break;
    case Rcreate:
        n += 13 + 4;  // qid + iounit
        break;
    case Tread:
        n += 4 + 8 + 4;  // fid + offset + count
        break;
    case Rread:
        n += 4 + fc->read_r.count;
        break;
    case Twrite:
        n += 4 + 8 + 4 + fc->write.count;  // fid + offset + count + data
        break;
    case Rwrite:
        n += 4;  // count
        break;
    case Tclunk:
    case Tremove:
    case Tstat:
        n += 4;  // fid
        break;
    case Rclunk:
    case Rremove:
        break;
    case Rstat:
        n += 2 + fc->stat_r.nstat;
        break;
    case Twstat:
        n += 4 + 2 + fc->wstat.nstat;  // fid + nstat + stat
        break;
    case Rwstat:
        break;
    default:
        return 0;
    }
    
    return n;
}

// Pack message into buffer
int pack_msg(Fcall *fc, uint8_t *buf) {
    uint32_t size = size_msg(fc);
    if (size == 0 || size > MAXMSG)
        return -1;
    
    uint8_t *p = buf;
    put4(p, size); p += 4;
    put1(p, fc->type); p += 1;
    put2(p, fc->tag); p += 2;
    
    switch(fc->type) {
    case Tversion:
    case Rversion:
        put4(p, fc->version.msize); p += 4;
        pstr(p, fc->version.version, 256); 
        break;
        
    case Tattach:
        put4(p, fc->fid); p += 4;
        put4(p, fc->attach.afid); p += 4;
        pstr(p, fc->attach.uname, 256); p += 2 + strlen(fc->attach.uname);
        pstr(p, fc->attach.aname, 256);
        break;
        
    case Rattach:
        pqid(p, &fc->attach_r.qid);
        break;
        
    case Rerror:
        pstr(p, fc->error.ename, 256);
        break;
        
    case Tflush:
        put2(p, fc->flush.oldtag);
        break;
        
    case Rflush:
        break;
        
    case Twalk:
        put4(p, fc->fid); p += 4;
        put4(p, fc->walk.newfid); p += 4;
        put2(p, fc->walk.nwname); p += 2;
        for (int i = 0; i < fc->walk.nwname; i++) {
            pstr(p, fc->walk.wname[i], 256);
            p += 2 + strlen(fc->walk.wname[i]);
        }
        break;
        
    case Rwalk:
        put2(p, fc->walk_r.nwqid); p += 2;
        for (int i = 0; i < fc->walk_r.nwqid; i++) {
            pqid(p, &fc->walk_r.wqid[i]);
            p += 13;
        }
        break;
        
    case Topen:
        put4(p, fc->fid); p += 4;
        put1(p, fc->open.mode);
        break;
        
    case Ropen:
        pqid(p, &fc->open_r.qid); p += 13;
        put4(p, fc->open_r.iounit);
        break;
        
    case Tcreate:
        put4(p, fc->fid); p += 4;
        pstr(p, fc->create.name, 256); p += 2 + strlen(fc->create.name);
        put4(p, fc->create.perm); p += 4;
        put1(p, fc->create.mode);
        break;
        
    case Rcreate:
        pqid(p, &fc->create_r.qid); p += 13;
        put4(p, fc->create_r.iounit);
        break;
        
    case Tread:
        put4(p, fc->fid); p += 4;
        put8(p, fc->read.offset); p += 8;
        put4(p, fc->read.count);
        break;
        
    case Rread:
        put4(p, fc->read_r.count); p += 4;
        memcpy(p, fc->read_r.data, fc->read_r.count);
        break;
        
    case Twrite:
        put4(p, fc->fid); p += 4;
        put8(p, fc->write.offset); p += 8;
        put4(p, fc->write.count); p += 4;
        memcpy(p, fc->write.data, fc->write.count);
        break;
        
    case Rwrite:
        put4(p, fc->write_r.count);
        break;
        
    case Tclunk:
    case Tremove:
    case Tstat:
        put4(p, fc->fid);
        break;
        
    case Rclunk:
    case Rremove:
        break;
        
    case Rstat:
        put2(p, fc->stat_r.nstat); p += 2;
        memcpy(p, fc->stat_r.stat, fc->stat_r.nstat);
        break;
        
    case Twstat:
        put4(p, fc->fid); p += 4;
        put2(p, fc->wstat.nstat); p += 2;
        memcpy(p, fc->wstat.stat, fc->wstat.nstat);
        break;
        
    case Rwstat:
        break;
    }
    
    return size;
}

// Unpack message from buffer
int unpack_msg(uint8_t *buf, uint32_t size, Fcall *fc) {
    if (size < 7)
        return -1;
    
    uint8_t *p = buf;
    uint32_t msize = get4(p); p += 4;
    
    if (msize != size)
        return -1;
    
    fc->type = get1(p); p += 1;
    fc->tag = get2(p); p += 2;
    
    // Initialize the fid to 0 by default
    fc->fid = 0;
    
    switch(fc->type) {
    case Tversion:
    case Rversion:
        if (size < 4 + 1 + 2 + 4 + 2)
            return -1;
        fc->version.msize = get4(p); p += 4;
        gstr(p, fc->version.version, sizeof(fc->version.version));
        break;
        
    case Tattach:
        if (size < 4 + 1 + 2 + 4 + 4 + 2 + 2)
            return -1;
        fc->fid = get4(p); p += 4;
        fc->attach.afid = get4(p); p += 4;
        gstr(p, fc->attach.uname, sizeof(fc->attach.uname));
        p += 2 + get2(p);
        gstr(p, fc->attach.aname, sizeof(fc->attach.aname));
        break;
        
    case Tflush:
        if (size < 4 + 1 + 2 + 2)
            return -1;
        fc->flush.oldtag = get2(p);
        break;
        
    case Twalk:
        if (size < 4 + 1 + 2 + 4 + 4 + 2)
            return -1;
        fc->fid = get4(p); p += 4;
        fc->walk.newfid = get4(p); p += 4;
        fc->walk.nwname = get2(p); p += 2;
        if (fc->walk.nwname > 16)
            return -1;
        for (int i = 0; i < fc->walk.nwname; i++) {
            if (p + 2 > buf + size)
                return -1;
            gstr(p, fc->walk.wname[i], sizeof(fc->walk.wname[i]));
            p += 2 + get2(p);
        }
        break;
        
    case Topen:
        if (size < 4 + 1 + 2 + 4 + 1)
            return -1;
        fc->fid = get4(p); p += 4;
        fc->open.mode = get1(p);
        break;
        
    case Tcreate:
        if (size < 4 + 1 + 2 + 4 + 2)
            return -1;
        fc->fid = get4(p); p += 4;
        gstr(p, fc->create.name, sizeof(fc->create.name));
        p += 2 + get2(p);
        if (p + 4 + 1 > buf + size)
            return -1;
        fc->create.perm = get4(p); p += 4;
        fc->create.mode = get1(p);
        break;
        
    case Tread:
        if (size < 4 + 1 + 2 + 4 + 8 + 4)
            return -1;
        fc->fid = get4(p); p += 4;
        fc->read.offset = get8(p); p += 8;
        fc->read.count = get4(p);
        break;
        
    case Twrite:
        if (size < 4 + 1 + 2 + 4 + 8 + 4)
            return -1;
        fc->fid = get4(p); p += 4;
        fc->write.offset = get8(p); p += 8;
        fc->write.count = get4(p); p += 4;
        if (p + fc->write.count > buf + size)
            return -1;
        fc->write.data = p;
        break;
        
    case Tclunk:
    case Tremove:
    case Tstat:
        if (size < 4 + 1 + 2 + 4)
            return -1;
        fc->fid = get4(p);
        break;
        
    case Twstat:
        if (size < 4 + 1 + 2 + 4 + 2)
            return -1;
        fc->fid = get4(p); p += 4;
        fc->wstat.nstat = get2(p); p += 2;
        if (p + fc->wstat.nstat > buf + size)
            return -1;
        fc->wstat.stat = p;
        break;
        
    default:
        // Unknown message type
        fprintf(stderr, "unpack_msg: unknown message type %d\n", fc->type);
        return -1;
    }
    
    return 0;
}

const char* msg_type_str(uint8_t type) {
    switch(type) {
    case Tversion: return "Tversion";
    case Rversion: return "Rversion";
    case Tauth: return "Tauth";
    case Rauth: return "Rauth";
    case Tattach: return "Tattach";
    case Rattach: return "Rattach";
    case Tflush: return "Tflush";
    case Rflush: return "Rflush";
    case Twalk: return "Twalk";
    case Rwalk: return "Rwalk";
    case Topen: return "Topen";
    case Ropen: return "Ropen";
    case Tcreate: return "Tcreate";
    case Rcreate: return "Rcreate";
    case Tread: return "Tread";
    case Rread: return "Rread";
    case Twrite: return "Twrite";
    case Rwrite: return "Rwrite";
    case Tclunk: return "Tclunk";
    case Rclunk: return "Rclunk";
    case Tremove: return "Tremove";
    case Rremove: return "Rremove";
    case Tstat: return "Tstat";
    case Rstat: return "Rstat";
    case Twstat: return "Twstat";
    case Rwstat: return "Rwstat";
    case Terror: return "Terror";
    case Rerror: return "Rerror";
    default: return "Unknown";
    }
}

// Pack stat structure for Rstat - strictly following 9P2000 spec
uint16_t pack_stat(uint8_t *buf, char *name, struct stat *st) {
    uint8_t *p = buf;
    uint8_t *size_p;
    uint16_t namelen = strlen(name);
    
    // Reserve space for size[2] - total size of stat structure
    size_p = p;
    p += 2;
    
    // type[2] dev[4] - for kernel use, set to 0
    put2(p, 0); p += 2;  // type
    put4(p, 0); p += 4;  // dev
    
    // qid[13] - type[1] vers[4] path[8]
    uint8_t qtype = S_ISDIR(st->st_mode) ? QTDIR : QTFILE;
    put1(p, qtype); p += 1;
    put4(p, st->st_mtime); p += 4;  // version is mtime
    put8(p, st->st_ino); p += 8;    // path is inode number
    
    // mode[4] - permissions and directory bit
    uint32_t mode = st->st_mode & 0777;
    if (S_ISDIR(st->st_mode))
        mode |= DMDIR;
    put4(p, mode); p += 4;
    
    // atime[4] mtime[4]
    put4(p, st->st_atime); p += 4;
    put4(p, st->st_mtime); p += 4;
    
    // length[8] - file size
    uint64_t length = st->st_size;
    put8(p, length); p += 8;
    
    // name[s] - filename
    pstr(p, name, 255); p += 2 + namelen;
    
    // uid[s] gid[s] muid[s] - owner strings
    pstr(p, "none", 255); p += 2 + 4;  // uid
    pstr(p, "none", 255); p += 2 + 4;  // gid
    pstr(p, "none", 255); p += 2 + 4;  // muid
    
    // Now go back and set the total size
    uint16_t total_size = (p - buf) - 2;  // Don't include size field itself
    put2(size_p, total_size);
    
    return p - buf;
}
#ifndef _9P_PROTO_H
#define _9P_PROTO_H

#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#define MAXMSG 8192
#define IOHDRSZ 24
#define NOTAG (uint16_t)(~0)
#define NOFID (uint32_t)(~0)

// Additional Qid types
#define QTSYMLINK 0x02   // Symbolic link

// Message types
enum {
    Tversion = 100, Rversion,
    Tauth = 102, Rauth,
    Tattach = 104, Rattach,
    Terror = 106, Rerror,
    Tflush = 108, Rflush,
    Twalk = 110, Rwalk,
    Topen = 112, Ropen,
    Tcreate = 114, Rcreate,
    Tread = 116, Rread,
    Twrite = 118, Rwrite,
    Tclunk = 120, Rclunk,
    Tremove = 122, Rremove,
    Tstat = 124, Rstat,
    Twstat = 126, Rwstat,
};

// File types
enum {
    QTDIR = 0x80,
    QTAPPEND = 0x40,
    QTEXCL = 0x20,
    QTMOUNT = 0x10,
    QTAUTH = 0x08,
    QTTMP = 0x04,
    QTFILE = 0x00
};

// File modes
enum {
    OREAD = 0,
    OWRITE = 1,
    ORDWR = 2,
    OEXEC = 3,
    OTRUNC = 0x10,
    OCEXEC = 0x20,
    ORCLOSE = 0x40,
};

// Directory mode bit
#define DMDIR 0x80000000

// Structures
typedef struct Qid {
    uint64_t path;
    uint32_t vers;
    uint8_t type;
} Qid;

typedef struct Fcall {
    uint8_t type;
    uint16_t tag;
    uint32_t fid;
    
    union {
        struct {
            uint32_t msize;
            char version[256];
        } version;
        
        struct {
            uint32_t afid;
            char uname[256];
            char aname[256];
        } attach;
        
        struct {
            Qid qid;
        } attach_r;
        
        struct {
            uint32_t newfid;
            uint16_t nwname;
            char wname[16][256];
        } walk;
        
        struct {
            uint16_t nwqid;
            Qid wqid[16];
        } walk_r;
        
        struct {
            uint8_t mode;
        } open;
        
        struct {
            Qid qid;
            uint32_t iounit;
        } open_r;
        
        struct {
            char name[256];
            uint32_t perm;
            uint8_t mode;
        } create;
        
        struct {
            Qid qid;
            uint32_t iounit;
        } create_r;
        
        struct {
            uint64_t offset;
            uint32_t count;
        } read;
        
        struct {
            uint32_t count;
            uint8_t *data;
        } read_r;
        
        struct {
            uint64_t offset;
            uint32_t count;
            uint8_t *data;
        } write;
        
        struct {
            uint32_t count;
        } write_r;
        
        struct {
            uint16_t nstat;
            uint8_t *stat;
        } stat_r;
        
        struct {
            uint16_t nstat;
            uint8_t *stat;
        } wstat;
        
        struct {
            char ename[256];
        } error;
        
        struct {
            uint16_t oldtag;
        } flush;
    };
} Fcall;

// Functions
void put1(uint8_t *p, uint8_t v);
void put2(uint8_t *p, uint16_t v);
void put4(uint8_t *p, uint32_t v);
void put8(uint8_t *p, uint64_t v);
void pqid(uint8_t *p, Qid *q);
void pstr(uint8_t *p, char *s, uint16_t max);

uint8_t get1(uint8_t *p);
uint16_t get2(uint8_t *p);
uint32_t get4(uint8_t *p);
uint64_t get8(uint8_t *p);
void gqid(uint8_t *p, Qid *q);
char* gstr(uint8_t *p, char *buf, uint16_t max);

uint32_t size_msg(Fcall *fc);
int pack_msg(Fcall *fc, uint8_t *buf);
int unpack_msg(uint8_t *buf, uint32_t size, Fcall *fc);
const char* msg_type_str(uint8_t type);

// Stat structure packing
uint16_t pack_stat(uint8_t *buf, char *name, struct stat *st);

#endif // _9P_PROTO_H
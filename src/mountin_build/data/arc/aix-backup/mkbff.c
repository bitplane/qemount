/*
 * Create a minimal AIX backup-by-name (BFF) archive.
 * Usage: mkbff output.bff directory/
 *
 * Produces a valid by-name format file with magic 0x09006bea,
 * readable by AIX restore(1) and file(1).
 *
 * Format reference:
 *   /usr/include/sys/backup.h on AIX
 *   IBM AIX 7.2 Files Reference, "BFF File Format"
 *
 * Header common prefix (6 bytes):
 *   byte 0:   len     - header size in 32-bit dwords
 *   byte 1:   type    - record type (0=VOLUME, 7=END, 10=NAME_X)
 *   bytes 2-3: magic  - 0x6BEA on disk (file(1) checks all 4 bytes as
 *                        be32 0x09006bea for VOLUME where len=9, type=0)
 *   bytes 4-5: checksum
 */

#include <arpa/inet.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

#define TP_BSIZE      1024
#define BFF_MAGIC     0x6BEA    /* on-disk magic bytes (big-endian u16) */
#define CHECKSUM      84446
#define CLUSTER_SIZE  51200

/* Record types */
#define FS_VOLUME     0
#define FS_END        7
#define FS_NAME_X     10

static void put_be16(unsigned char *p, uint16_t v) {
    p[0] = (v >> 8) & 0xff;
    p[1] = v & 0xff;
}

static void put_be32(unsigned char *p, uint32_t v) {
    p[0] = (v >> 24) & 0xff;
    p[1] = (v >> 16) & 0xff;
    p[2] = (v >> 8) & 0xff;
    p[3] = v & 0xff;
}

/*
 * BFF checksum: sum all big-endian 16-bit words in the header,
 * treating the checksum field (bytes 4-5) as zero.
 * Stored value = CHECKSUM - sum.
 */
static uint16_t bff_checksum(const unsigned char *buf, size_t len) {
    uint32_t sum = 0;
    for (size_t i = 0; i < len; i += 2) {
        if (i == 4) continue;
        uint16_t word = ((uint16_t)buf[i] << 8);
        if (i + 1 < len) word |= buf[i + 1];
        sum += word;
    }
    return (uint16_t)(CHECKSUM - (sum & 0xffff));
}

/* Write the 6-byte common header prefix */
static void write_hdr(unsigned char *buf, uint8_t len_dw, uint8_t type) {
    buf[0] = len_dw;
    buf[1] = type;
    put_be16(buf + 2, BFF_MAGIC);
    /* bytes 4-5 (checksum) filled by caller */
}

/*
 * FS_VOLUME record (padded to TP_BSIZE = 1024 bytes).
 *
 * Offsets 0-35 (9 dwords):
 *   0: len=9, type=0, magic, checksum  (6 bytes)
 *   6: volnum (be16)
 *   8: date (be32)
 *  12: dumpdate (be32)
 *  16: numwds (be32) - total 32-bit words this volume
 *  20: disk[16]
 *
 * Extended fields in the padding area (still within the 1024-byte block):
 *  36: fsname[16]
 *  52: user[16]
 */
static int write_volume(FILE *fp, uint32_t total_words) {
    unsigned char buf[TP_BSIZE];
    memset(buf, 0, sizeof(buf));

    write_hdr(buf, 9, FS_VOLUME);
    put_be16(buf + 6, 1);

    uint32_t now = (uint32_t)time(NULL);
    put_be32(buf + 8, now);
    put_be32(buf + 12, now);
    put_be32(buf + 16, total_words);
    strncpy((char *)buf + 20, "/dev/rhdisk0", 16);
    strncpy((char *)buf + 36, "/", 16);
    strncpy((char *)buf + 52, "root", 16);

    put_be16(buf + 4, bff_checksum(buf, 9 * 4));

    if (fwrite(buf, 1, TP_BSIZE, fp) != TP_BSIZE) return -1;
    return 0;
}

/*
 * FS_NAME_X record for one file, followed by its data.
 *
 *   0: common header (6 bytes)
 *   6: mode (be32)
 *  10: uid (be16)
 *  12: gid (be16)
 *  14: size_hi (be16)
 *  16: size_lo (be32)
 *  20: atime (be32)
 *  24: mtime (be32)
 *  28: nlink (be16)
 *  30: name_len (be16) - including null
 *  32: name[] (null-terminated, dword-padded)
 *
 * File data follows immediately, padded to CLUSTER_SIZE.
 */
static int write_file(FILE *fp, const char *arcname, const char *realpath) {
    struct stat st;
    if (stat(realpath, &st)) {
        perror(realpath);
        return -1;
    }

    size_t name_len = strlen(arcname) + 1;
    size_t hdr_bytes = (32 + name_len + 3) & ~(size_t)3;
    uint8_t hdr_dw = (uint8_t)(hdr_bytes / 4);

    unsigned char *buf = calloc(1, hdr_bytes);
    if (!buf) return -1;

    write_hdr(buf, hdr_dw, FS_NAME_X);
    put_be32(buf + 6, (uint32_t)st.st_mode);
    put_be16(buf + 10, (uint16_t)st.st_uid);
    put_be16(buf + 12, (uint16_t)st.st_gid);
    put_be16(buf + 14, (uint16_t)((st.st_size >> 32) & 0xffff));
    put_be32(buf + 16, (uint32_t)(st.st_size & 0xffffffff));
    put_be32(buf + 20, (uint32_t)st.st_atime);
    put_be32(buf + 24, (uint32_t)st.st_mtime);
    put_be16(buf + 28, (uint16_t)st.st_nlink);
    put_be16(buf + 30, (uint16_t)name_len);
    memcpy(buf + 32, arcname, name_len);

    put_be16(buf + 4, bff_checksum(buf, hdr_bytes));

    if (fwrite(buf, 1, hdr_bytes, fp) != hdr_bytes) {
        free(buf);
        return -1;
    }
    free(buf);

    /* Write file data */
    FILE *in = fopen(realpath, "rb");
    if (!in) {
        perror(realpath);
        return -1;
    }

    size_t total = 0;
    unsigned char data[4096];
    size_t n;
    while ((n = fread(data, 1, sizeof(data), in)) > 0) {
        if (fwrite(data, 1, n, fp) != n) {
            fclose(in);
            return -1;
        }
        total += n;
    }
    fclose(in);

    /* Pad to cluster boundary */
    size_t remainder = total % CLUSTER_SIZE;
    if (remainder) {
        size_t pad = CLUSTER_SIZE - remainder;
        unsigned char zero[512];
        memset(zero, 0, sizeof(zero));
        while (pad > 0) {
            size_t chunk = pad < sizeof(zero) ? pad : sizeof(zero);
            if (fwrite(zero, 1, chunk, fp) != chunk) return -1;
            pad -= chunk;
        }
    }

    return 0;
}

static int write_end(FILE *fp) {
    unsigned char buf[8];
    memset(buf, 0, sizeof(buf));

    write_hdr(buf, 2, FS_END);
    put_be16(buf + 4, bff_checksum(buf, 8));

    if (fwrite(buf, 1, 8, fp) != 8) return -1;
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s output.bff dir/\n", argv[0]);
        return 1;
    }

    FILE *fp = fopen(argv[1], "wb");
    if (!fp) {
        perror(argv[1]);
        return 1;
    }

    if (write_volume(fp, 0)) {
        fclose(fp);
        return 1;
    }

    DIR *d = opendir(argv[2]);
    if (!d) {
        perror(argv[2]);
        fclose(fp);
        return 1;
    }

    struct dirent *ent;
    char path[512];
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        snprintf(path, sizeof(path), "%s/%s", argv[2], ent->d_name);
        struct stat st;
        if (stat(path, &st) || !S_ISREG(st.st_mode)) continue;
        if (write_file(fp, ent->d_name, path)) {
            closedir(d);
            fclose(fp);
            return 1;
        }
    }
    closedir(d);

    write_end(fp);

    /* Patch volume header with actual word count */
    long total_bytes = ftell(fp);
    uint32_t total_words = (uint32_t)(total_bytes / 4);
    fseek(fp, 0, SEEK_SET);
    write_volume(fp, total_words);

    fclose(fp);
    return 0;
}

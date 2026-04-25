/*
 * Minimal Macintosh File System (MFS) image creator
 * Based on Apple's "Inside Macintosh, Volume II" (1985) and
 * CiderPress2 MFS format documentation.
 *
 * Creates MFS filesystem images for testing, optionally populated from a
 * directory tree via -d. MFS was the original Macintosh filesystem (1984),
 * a flat filesystem where folders were a Finder illusion.
 *
 * All on-disk values are big-endian (68k Macintosh).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <time.h>
#include <dirent.h>
#include <sys/stat.h>
#include <arpa/inet.h>  /* htons, htonl */

#define BLOCK_SIZE      512
#define ALLOC_BLK_SIZE  1024    /* allocation block size */
#define MFS_SIGNATURE   0xD2D7
#define MAX_FILES       4094
#define MAX_ALLOC_BLKS  4094    /* 12-bit map, 0x000 and 0x001 reserved values */

/* Mac epoch: seconds between 1904-01-01 and 1970-01-01 */
#define MAC_EPOCH_OFFSET 2082844800U

/* Allocation block map values */
#define ABLK_FREE       0x000
#define ABLK_LAST       0x001
#define ABLK_RESERVED   0xFFF

/* Big-endian writers */
static void put_be16(uint8_t *p, uint16_t v) { p[0] = v >> 8; p[1] = v; }
static void put_be32(uint8_t *p, uint32_t v) { p[0] = v >> 24; p[1] = v >> 16; p[2] = v >> 8; p[3] = v; }

/* Global state */
static int      fs_fd;
static uint8_t *image;          /* entire image in memory */
static uint32_t image_size;
static uint32_t num_alloc_blks; /* number of allocation blocks */
static uint32_t alloc_blk_start; /* first alloc block (in 512-byte blocks) */
static uint32_t dir_start;      /* first directory block number */
static uint32_t dir_blocks;     /* number of directory blocks */
static uint32_t mdb_blocks;     /* number of 512-byte blocks the MDB+map occupies */
static uint32_t now_mac;        /* current time in Mac epoch */

/* 12-bit allocation block map (in memory, indexed from 0) */
static uint16_t blk_map[MAX_ALLOC_BLKS];
static uint32_t next_alloc_blk;  /* next free allocation block (0-based) */

/* Directory state */
static uint32_t dir_used;       /* bytes used in directory area */
static uint32_t next_file_num;  /* next file number to assign */
static uint32_t file_count;     /* number of files */

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.mfs: %s\n", msg);
    exit(1);
}

/* Allocate contiguous allocation blocks, return first block index (0-based)
 * Note: block map entries use values offset by 2 (blocks 0,1 are reserved).
 * So map entry for alloc block N contains N+2 as the "next" pointer. */
static uint32_t alloc_blocks(uint32_t count)
{
    if (count == 0)
        die("alloc_blocks called with count=0");
    if (next_alloc_blk + count > num_alloc_blks)
        die("no free allocation blocks");

    uint32_t first = next_alloc_blk;

    /* Chain the blocks: each points to next, last gets ABLK_LAST */
    for (uint32_t i = 0; i < count - 1; i++)
        blk_map[first + i] = first + i + 1 + 2;  /* +2 because map entries are offset by 2 */

    blk_map[first + count - 1] = ABLK_LAST;
    next_alloc_blk += count;

    return first;
}

/* Add a file to the directory */
static void add_file(const char *name, const void *data, uint32_t size,
                     const char *type, const char *creator)
{
    if (file_count >= MAX_FILES)
        die("too many files");

    size_t raw_len = strlen(name);
    if (raw_len > 255) {
        fprintf(stderr, "mkfs.mfs: warning: name truncated to 255 bytes: %s\n", name);
        raw_len = 255;
    }
    uint8_t name_len = raw_len;

    /* Entry size: 51 bytes fixed + name_len, padded to word boundary */
    uint32_t entry_size = 0x32 + 1 + name_len;
    if (entry_size & 1) entry_size++;  /* pad to 16-bit boundary */

    uint32_t dir_area_size = dir_blocks * BLOCK_SIZE;
    uint8_t *dir_base = image + dir_start * BLOCK_SIZE;

    /* Check if entry would cross a block boundary */
    uint32_t block_offset = dir_used % BLOCK_SIZE;
    if (block_offset + entry_size > BLOCK_SIZE) {
        /* Skip to next block */
        /* Mark end of entries in current block with flFlags=0 (already zeroed) */
        dir_used = (dir_used / BLOCK_SIZE + 1) * BLOCK_SIZE;
    }

    if (dir_used + entry_size > dir_area_size)
        die("directory full");

    /* Write file data fork */
    uint32_t first_blk = 0;
    uint32_t phys_len = 0;
    if (size > 0) {
        uint32_t num_blocks = (size + ALLOC_BLK_SIZE - 1) / ALLOC_BLK_SIZE;
        first_blk = alloc_blocks(num_blocks);
        phys_len = num_blocks * ALLOC_BLK_SIZE;

        /* Copy data */
        const uint8_t *src = data;
        uint32_t remaining = size;
        for (uint32_t i = 0; i < num_blocks; i++) {
            uint32_t offset = (alloc_blk_start * BLOCK_SIZE) + (first_blk + i) * ALLOC_BLK_SIZE;
            uint32_t chunk = remaining < ALLOC_BLK_SIZE ? remaining : ALLOC_BLK_SIZE;
            memcpy(image + offset, src, chunk);
            src += chunk;
            remaining -= chunk;
        }
    }

    /* Build directory entry */
    uint8_t *ent = dir_base + dir_used;
    ent[0x00] = 0x80;                   /* flFlags: in use */
    ent[0x01] = 0x00;                   /* flTyp: version 0 */

    /* flUsrWds: Finder info */
    if (type && strlen(type) == 4)
        memcpy(ent + 0x02, type, 4);    /* fdType */
    if (creator && strlen(creator) == 4)
        memcpy(ent + 0x06, creator, 4); /* fdCreator */
    /* fdFlags, fdLocation, fdFldr: leave as zero */

    put_be32(ent + 0x12, next_file_num++);  /* flFlNum */

    /* Data fork */
    if (size > 0)
        put_be16(ent + 0x16, first_blk + 2);  /* flStBlk (+2 for reserved blocks) */
    put_be32(ent + 0x18, size);             /* flLgLen */
    put_be32(ent + 0x1C, phys_len);         /* flPyLen */

    /* Resource fork: empty */
    /* flRStBlk, flRLgLen, flRPyLen: leave as zero */

    put_be32(ent + 0x2A, now_mac);          /* flCrDat */
    put_be32(ent + 0x2E, now_mac);          /* flMdDat */

    /* Filename */
    ent[0x32] = name_len;
    memcpy(ent + 0x33, name, name_len);

    dir_used += entry_size;
    file_count++;
}

/* Pack 12-bit allocation block map into the MDB area */
static void pack_block_map(void)
{
    /* Block map starts at offset 0x40 within the MDB (block 2) */
    uint8_t *map_base = image + 2 * BLOCK_SIZE + 0x40;

    for (uint32_t i = 0; i < num_alloc_blks; i += 2) {
        uint16_t a = blk_map[i];
        uint16_t b = (i + 1 < num_alloc_blks) ? blk_map[i + 1] : 0;

        /* Pack two 12-bit values into 3 bytes: AB CD EF -> 0xABC, 0xDEF */
        uint32_t byte_off = (i / 2) * 3;
        map_base[byte_off + 0] = (a >> 4) & 0xFF;
        map_base[byte_off + 1] = ((a & 0x0F) << 4) | ((b >> 8) & 0x0F);
        map_base[byte_off + 2] = b & 0xFF;
    }
}

/* Write the Master Directory Block */
static void write_mdb(void)
{
    uint8_t *mdb = image + 2 * BLOCK_SIZE;

    /* Volume Information (64 bytes at offset 0x00) */
    put_be16(mdb + 0x00, MFS_SIGNATURE);    /* drSigWord */
    put_be32(mdb + 0x02, now_mac);          /* drCrDate */
    put_be32(mdb + 0x06, 0);               /* drLsBkUp */
    put_be16(mdb + 0x0A, 0);               /* drAtrb */
    put_be16(mdb + 0x0C, file_count);       /* drNmFls */
    put_be16(mdb + 0x0E, dir_start);        /* drDirSt */
    put_be16(mdb + 0x10, dir_blocks);       /* drBlLen */
    put_be16(mdb + 0x12, num_alloc_blks);   /* drNmAlBlks */
    put_be32(mdb + 0x14, ALLOC_BLK_SIZE);   /* drAlBlkSiz */
    put_be32(mdb + 0x18, ALLOC_BLK_SIZE);   /* drClpSiz (default clump) */
    put_be16(mdb + 0x1C, alloc_blk_start);  /* drAlBlSt (first alloc block start) */
    put_be32(mdb + 0x1E, next_file_num);    /* drNxtFNum */

    /* Count free blocks */
    uint32_t free_blks = 0;
    for (uint32_t i = 0; i < num_alloc_blks; i++)
        if (blk_map[i] == ABLK_FREE)
            free_blks++;
    put_be16(mdb + 0x22, free_blks);        /* drFreeBks */

    /* Volume name */
    const char *vol_name = "Untitled";
    uint8_t vn_len = strlen(vol_name);
    mdb[0x24] = vn_len;
    memcpy(mdb + 0x25, vol_name, vn_len);

    /* Pack the 12-bit block map after the volume info */
    pack_block_map();

    /* Write backup MDB at the end of the volume (mirrors the full MDB+map) */
    uint32_t backup_block = (image_size / BLOCK_SIZE) - mdb_blocks;
    memcpy(image + backup_block * BLOCK_SIZE, mdb, mdb_blocks * BLOCK_SIZE);
}

/* Map a file extension to Mac type/creator codes */
static void type_for_ext(const char *name, char *type, char *creator)
{
    memcpy(type, "????", 4);
    memcpy(creator, "????", 4);

    const char *dot = strrchr(name, '.');
    if (!dot) return;
    dot++;

    if (strcasecmp(dot, "txt") == 0 || strcasecmp(dot, "text") == 0) {
        memcpy(type, "TEXT", 4);
        memcpy(creator, "ttxt", 4);
    } else if (strcasecmp(dot, "c") == 0 || strcasecmp(dot, "h") == 0) {
        memcpy(type, "TEXT", 4);
        memcpy(creator, "ttxt", 4);
    } else if (strcasecmp(dot, "bin") == 0) {
        memcpy(type, "BINA", 4);
        memcpy(creator, "hDmp", 4);
    }
}

/* Populate from a directory tree (flattened — MFS has no real directories) */
static void populate(const char *src_path, const char *prefix)
{
    DIR *d = opendir(src_path);
    if (!d) { perror(src_path); exit(1); }

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;

        /* ':' is the Mac path separator and would be ambiguous after flattening */
        if (strchr(ent->d_name, ':')) {
            fprintf(stderr, "mkfs.mfs: filename contains ':' (Mac path separator): %s\n",
                    ent->d_name);
            exit(1);
        }

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, ent->d_name);

        /* Build flattened name with colon separator (Mac path convention) */
        char flat_name[512];
        if (prefix[0])
            snprintf(flat_name, sizeof(flat_name), "%s:%s", prefix, ent->d_name);
        else
            snprintf(flat_name, sizeof(flat_name), "%s", ent->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) { perror(child_path); exit(1); }

        if (S_ISDIR(st.st_mode)) {
            populate(child_path, flat_name);
        } else if (S_ISREG(st.st_mode)) {
            /* Read file into memory */
            uint8_t *data = NULL;
            uint32_t size = st.st_size;
            if (size > 0) {
                data = malloc(size);
                if (!data) { perror("malloc"); exit(1); }
                int f = open(child_path, O_RDONLY);
                if (f < 0) { perror(child_path); exit(1); }

                uint32_t got = 0;
                while (got < size) {
                    ssize_t n = read(f, data + got, size - got);
                    if (n < 0) { perror(child_path); exit(1); }
                    if (n == 0) {
                        fprintf(stderr, "mkfs.mfs: short read on %s (got %u of %u)\n",
                                child_path, got, size);
                        exit(1);
                    }
                    got += n;
                }
                close(f);
            }

            char type[5] = {0}, creator[5] = {0};
            type_for_ext(ent->d_name, type, creator);
            add_file(flat_name, data, size, type, creator);
            free(data);
        }
    }
    closedir(d);
}

int main(int argc, char **argv)
{
    char *populate_dir = NULL;
    char *vol_name = NULL;
    int size_kb = 400;  /* default: 400KB floppy */

    int opt;
    while ((opt = getopt(argc, argv, "d:s:v:")) != -1) {
        switch (opt) {
        case 'd': populate_dir = optarg; break;
        case 's': size_kb = atoi(optarg); break;
        case 'v': vol_name = optarg; break;
        default:
            fprintf(stderr, "Usage: %s [-d directory] [-s size_kb] [-v volume_name] <output>\n",
                    argv[0]);
            return 1;
        }
    }
    if (optind >= argc) {
        fprintf(stderr, "Usage: %s [-d directory] [-s size_kb] [-v volume_name] <output>\n",
                argv[0]);
        return 1;
    }

    char *filename = argv[optind];

    if (size_kb <= 0)
        die("size must be positive");

    /* Compute layout */
    uint64_t bytes = (uint64_t)size_kb * 1024;
    if (bytes > 0xFFFFFFFFu)
        die("image size exceeds 4 GB");
    image_size = (uint32_t)bytes;
    uint32_t total_blocks = image_size / BLOCK_SIZE;

    if (total_blocks < 20)
        die("volume too small");

    dir_blocks = 12;  /* same as 400KB floppy */
    if (size_kb > 400)
        dir_blocks = 24;
    if (size_kb > 2048)
        dir_blocks = 48;

    /* MDB+map sizing is circular: more alloc blocks → bigger map → bigger
     * MDB → fewer alloc blocks. Iterate until it converges. The MDB starts
     * at block 2 (after the boot blocks) and the backup at the end of the
     * volume mirrors it, so both sides take mdb_blocks each. */
    mdb_blocks = 2;
    for (int iter = 0; iter < 8; iter++) {
        if (total_blocks <= 2 + mdb_blocks + dir_blocks + mdb_blocks + 1)
            die("volume too small for layout");
        uint32_t alloc_start = 2 + mdb_blocks + dir_blocks;
        uint32_t alloc_area = (total_blocks - alloc_start - mdb_blocks) * BLOCK_SIZE;
        uint32_t nab = alloc_area / ALLOC_BLK_SIZE;
        if (nab > MAX_ALLOC_BLKS)
            nab = MAX_ALLOC_BLKS;
        uint32_t map_bytes = (nab * 12 + 7) / 8;
        uint32_t needed = (0x40 + map_bytes + BLOCK_SIZE - 1) / BLOCK_SIZE;
        if (needed <= mdb_blocks) {
            num_alloc_blks = nab;
            alloc_blk_start = alloc_start;
            dir_start = 2 + mdb_blocks;
            break;
        }
        mdb_blocks = needed;
    }
    if (alloc_blk_start == 0)
        die("MDB sizing did not converge");

    /* Mac epoch timestamp */
    now_mac = (uint32_t)time(NULL) + MAC_EPOCH_OFFSET;

    /* Allocate image */
    image = calloc(1, image_size);
    if (!image) die("cannot allocate image");

    /* Init state */
    memset(blk_map, 0, sizeof(blk_map));
    next_alloc_blk = 0;
    dir_used = 0;
    next_file_num = 1;
    file_count = 0;

    /* Populate from directory */
    if (populate_dir)
        populate(populate_dir, "");

    /* Write MDB (includes block map and backup) */
    write_mdb();

    /* Override volume name if specified */
    if (vol_name) {
        uint8_t *mdb = image + 2 * BLOCK_SIZE;
        uint8_t vn_len = strlen(vol_name);
        if (vn_len > 27) vn_len = 27;
        mdb[0x24] = vn_len;
        memcpy(mdb + 0x25, vol_name, vn_len);

        /* Update backup */
        uint32_t backup_block = (image_size / BLOCK_SIZE) - mdb_blocks;
        memcpy(image + backup_block * BLOCK_SIZE, mdb, mdb_blocks * BLOCK_SIZE);
    }

    /* Write image to file */
    fs_fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fs_fd < 0) { perror("open"); return 1; }
    if ((size_t)write(fs_fd, image, image_size) != image_size) {
        perror("write");
        return 1;
    }
    close(fs_fd);

    printf("Created MFS image: %s (%dKB, %u alloc blocks, %u files, sig=0x%X)\n",
           filename, size_kb, num_alloc_blks, file_count, MFS_SIGNATURE);

    free(image);
    return 0;
}

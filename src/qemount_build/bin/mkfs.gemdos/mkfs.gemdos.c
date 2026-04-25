/*
 * Minimal GEMDOS (Atari TOS) filesystem image creator
 * Based on the Atari Hard Disk File System Reference Guide by
 * Jean Louis-Guérin (DrCoolZic), 2014.
 *
 * Creates GEMDOS floppy/partition images for testing, optionally
 * populated from a directory tree via -d. GEMDOS is FAT12/16 with
 * Atari-specific boot sector conventions (68000 BRA.S, BE16 checksum).
 *
 * All BPB fields use big-endian byte order (Motorola 68000).
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
#include <ctype.h>

/* Defaults for a 720KB double-sided floppy */
#define DEFAULT_SIZE_KB     720
#define SECTOR_SIZE         512
#define SECTORS_PER_CLUSTER 2
#define CLUSTER_SIZE        (SECTOR_SIZE * SECTORS_PER_CLUSTER)
#define NUM_FATS            2
#define ROOT_DIR_ENTRIES    112
#define MEDIA_BYTE          0xF9    /* 720KB floppy */
#define FAT12_MAX_CLUSTERS  4084

/* Big-endian writers (Atari is 68000/big-endian) */
static void put_be16(uint8_t *p, uint16_t v) { p[0] = v >> 8; p[1] = v; }

/* Little-endian writers (BPB fields are actually LE in practice on Atari) */
static void put_le16(uint8_t *p, uint16_t v) { p[0] = v; p[1] = v >> 8; }
static void put_le32(uint8_t *p, uint32_t v) { p[0] = v; p[1] = v >> 8; p[2] = v >> 16; p[3] = v >> 24; }

/* Global state */
static uint8_t *image;
static uint32_t image_size;
static uint32_t total_sectors;
static uint32_t sectors_per_fat;
static uint32_t root_dir_sectors;
static uint32_t data_start;        /* first data sector */
static uint32_t total_clusters;
static uint16_t *fat;              /* in-memory FAT (16-bit entries, only low 12 used for FAT12) */
static uint32_t next_cluster;      /* next free cluster (2-based) */
static uint32_t root_dir_used;     /* bytes used in root directory */

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.gemdos: %s\n", msg);
    exit(1);
}

/* Compute and set the Atari boot sector checksum at offset 0x1FE.
 * Sum of all 256 big-endian 16-bit words must equal 0x1234. */
static void fix_checksum(void)
{
    uint16_t sum = 0;
    /* Sum words 0..254 (byte offsets 0..509) */
    for (int i = 0; i < 510; i += 2) {
        sum += (image[i] << 8) | image[i + 1];
    }
    /* Set checksum word so total sum == 0x1234 */
    uint16_t needed = 0x1234 - sum;
    put_be16(image + 0x1FE, needed);
}

/* Allocate a chain of clusters, return first cluster number (2-based) */
static uint32_t alloc_clusters(uint32_t count)
{
    if (count == 0)
        die("alloc_clusters called with count=0");
    if (next_cluster + count > total_clusters + 2)
        die("no free clusters");

    uint32_t first = next_cluster;
    for (uint32_t i = 0; i < count - 1; i++)
        fat[first + i] = first + i + 1;
    fat[first + count - 1] = 0xFFF; /* end of chain (FAT12) */
    next_cluster += count;
    return first;
}

/* Convert cluster number to byte offset in image */
static uint32_t cluster_offset(uint32_t cluster)
{
    return (data_start + (cluster - 2) * SECTORS_PER_CLUSTER) * SECTOR_SIZE;
}

/* Pack FAT12 entries into the image */
static void write_fat(uint32_t fat_start_sector)
{
    uint8_t *fat_area = image + fat_start_sector * SECTOR_SIZE;

    for (uint32_t i = 0; i < total_clusters + 2; i += 2) {
        uint16_t a = fat[i];
        uint16_t b = (i + 1 < total_clusters + 2) ? fat[i + 1] : 0;

        uint32_t byte_off = (i / 2) * 3;
        fat_area[byte_off + 0] = a & 0xFF;
        fat_area[byte_off + 1] = ((a >> 8) & 0x0F) | ((b & 0x0F) << 4);
        fat_area[byte_off + 2] = (b >> 4) & 0xFF;
    }
}

/* Convert filename to 8.3 format. "." and ".." are passed through verbatim
 * so that subdirectory dot/dotdot entries get the literal dot bytes that
 * FAT-style readers expect, rather than all-spaces. */
static void name_to_83(const char *name, char *out)
{
    memset(out, ' ', 11);

    if (strcmp(name, ".") == 0) { out[0] = '.'; return; }
    if (strcmp(name, "..") == 0) { out[0] = '.'; out[1] = '.'; return; }

    const char *dot = strrchr(name, '.');
    int base_len = dot ? (dot - name) : (int)strlen(name);
    if (base_len > 8) {
        fprintf(stderr, "mkfs.gemdos: warning: basename truncated to 8 chars: %s\n", name);
        base_len = 8;
    }

    for (int i = 0; i < base_len; i++)
        out[i] = toupper((unsigned char)name[i]);

    if (dot) {
        dot++;
        int ext_len = strlen(dot);
        if (ext_len > 3) {
            fprintf(stderr, "mkfs.gemdos: warning: extension truncated to 3 chars: %s\n", name);
            ext_len = 3;
        }
        for (int i = 0; i < ext_len; i++)
            out[8 + i] = toupper((unsigned char)dot[i]);
    }
}

/* FAT 8.3 disallows control chars, space, and these punctuation chars. */
static int illegal_83_char(unsigned char c)
{
    if (c < 0x20 || c == 0x7f) return 1;
    return strchr(" \"*+,/:;<=>?[\\]|", c) != NULL;
}

static void validate_user_name(const char *name)
{
    if (name[0] == '.') {
        fprintf(stderr, "mkfs.gemdos: name starts with dot (no basename): %s\n", name);
        exit(1);
    }
    int dots = 0;
    for (const char *p = name; *p; p++) {
        if (illegal_83_char((unsigned char)*p)) {
            fprintf(stderr, "mkfs.gemdos: illegal character 0x%02x in name: %s\n",
                    (unsigned char)*p, name);
            exit(1);
        }
        if (*p == '.' && ++dots > 1) {
            fprintf(stderr, "mkfs.gemdos: multiple dots in name: %s\n", name);
            exit(1);
        }
    }
}

static int root_has_name(const char *name83)
{
    uint32_t root_dir_offset = (1 + NUM_FATS * sectors_per_fat) * SECTOR_SIZE;
    for (uint32_t off = 0; off < root_dir_used; off += 32) {
        uint8_t *ent = image + root_dir_offset + off;
        if (ent[0] == 0x00 || ent[0] == 0xE5) continue;
        if (memcmp(ent, name83, 11) == 0) return 1;
    }
    return 0;
}

static int subdir_has_name(uint32_t dir_cluster, uint32_t dir_used, const char *name83)
{
    uint32_t cur = dir_cluster;
    uint32_t consumed = 0;
    while (consumed < dir_used) {
        uint32_t in_this = dir_used - consumed;
        if (in_this > CLUSTER_SIZE) in_this = CLUSTER_SIZE;
        uint8_t *base_ptr = image + cluster_offset(cur);
        for (uint32_t off = 0; off < in_this; off += 32) {
            uint8_t *ent = base_ptr + off;
            if (ent[0] == 0x00 || ent[0] == 0xE5) continue;
            if (memcmp(ent, name83, 11) == 0) return 1;
        }
        consumed += in_this;
        if (consumed < dir_used) cur = fat[cur];
    }
    return 0;
}

/* Encode date/time in DOS format */
static uint16_t dos_time(time_t t)
{
    struct tm *tm = localtime(&t);
    return (tm->tm_hour << 11) | (tm->tm_min << 5) | (tm->tm_sec / 2);
}

static uint16_t dos_date(time_t t)
{
    struct tm *tm = localtime(&t);
    return ((tm->tm_year - 80) << 9) | ((tm->tm_mon + 1) << 5) | tm->tm_mday;
}

/* Add a directory entry to the root directory */
static void add_root_entry(const char *name, uint8_t attr, uint32_t cluster,
                           uint32_t size, time_t mtime)
{
    uint32_t root_dir_offset = (1 + NUM_FATS * sectors_per_fat) * SECTOR_SIZE;
    uint32_t max_bytes = ROOT_DIR_ENTRIES * 32;

    if (root_dir_used + 32 > max_bytes)
        die("root directory full");

    char name83[11];
    name_to_83(name, name83);
    if (root_has_name(name83)) {
        fprintf(stderr, "mkfs.gemdos: duplicate 8.3 name in root: %s\n", name);
        exit(1);
    }

    uint8_t *ent = image + root_dir_offset + root_dir_used;
    memcpy(ent, name83, 11);
    ent[0x0B] = attr;
    put_le16(ent + 0x16, dos_time(mtime));
    put_le16(ent + 0x18, dos_date(mtime));
    put_le16(ent + 0x1A, cluster);
    put_le32(ent + 0x1C, size);

    root_dir_used += 32;
}

/* Add a directory entry to a subdirectory cluster chain */
static void add_subdir_entry(uint32_t dir_cluster, uint32_t *dir_used,
                             const char *name, uint8_t attr,
                             uint32_t cluster, uint32_t size, time_t mtime)
{
    char name83[11];
    name_to_83(name, name83);
    if (subdir_has_name(dir_cluster, *dir_used, name83)) {
        fprintf(stderr, "mkfs.gemdos: duplicate 8.3 name in subdirectory: %s\n", name);
        exit(1);
    }

    /* Find the right cluster in the chain */
    uint32_t cur = dir_cluster;
    uint32_t offset_in_dir = *dir_used;

    while (offset_in_dir >= CLUSTER_SIZE) {
        if (fat[cur] >= 0xFF8) {
            /* Allocate a new cluster */
            uint32_t new_clust = alloc_clusters(1);
            fat[cur] = new_clust;
            memset(image + cluster_offset(new_clust), 0, CLUSTER_SIZE);
        }
        cur = fat[cur];
        offset_in_dir -= CLUSTER_SIZE;
    }

    uint8_t *ent = image + cluster_offset(cur) + offset_in_dir;
    memcpy(ent, name83, 11);
    ent[0x0B] = attr;
    put_le16(ent + 0x16, dos_time(mtime));
    put_le16(ent + 0x18, dos_date(mtime));
    put_le16(ent + 0x1A, cluster);
    put_le32(ent + 0x1C, size);

    *dir_used += 32;
}

/* Write file data to clusters */
static uint32_t write_file(const char *path, uint32_t size)
{
    if (size == 0) return 0;

    uint32_t num_clusters = (size + CLUSTER_SIZE - 1) / CLUSTER_SIZE;
    uint32_t first = alloc_clusters(num_clusters);

    int fd = open(path, O_RDONLY);
    if (fd < 0) { perror(path); exit(1); }

    uint32_t remaining = size;
    for (uint32_t i = 0; i < num_clusters; i++) {
        uint32_t off = cluster_offset(first + i);
        uint32_t chunk = remaining < CLUSTER_SIZE ? remaining : CLUSTER_SIZE;
        ssize_t n = read(fd, image + off, chunk);
        if (n < 0) { perror(path); exit(1); }
        if ((uint32_t)n != chunk) {
            fprintf(stderr, "mkfs.gemdos: short read on %s (got %zd of %u)\n",
                    path, n, chunk);
            exit(1);
        }
        remaining -= chunk;
    }
    close(fd);
    return first;
}

/* Populate from a directory (recursive, but GEMDOS root is flat) */
static void populate_subdir(uint32_t dir_cluster, uint32_t *dir_used,
                            const char *src_path);

static void populate_root(const char *src_path)
{
    DIR *d = opendir(src_path);
    if (!d) { perror(src_path); exit(1); }

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;

        validate_user_name(ent->d_name);

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, ent->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) { perror(child_path); exit(1); }

        if (S_ISDIR(st.st_mode)) {
            uint32_t clust = alloc_clusters(1);
            memset(image + cluster_offset(clust), 0, CLUSTER_SIZE);
            add_root_entry(ent->d_name, 0x10, clust, 0, st.st_mtime);

            /* Add . and .. entries */
            uint32_t dir_used = 0;
            add_subdir_entry(clust, &dir_used, ".", 0x10, clust, 0, st.st_mtime);
            add_subdir_entry(clust, &dir_used, "..", 0x10, 0, 0, st.st_mtime);
            populate_subdir(clust, &dir_used, child_path);
        } else if (S_ISREG(st.st_mode)) {
            uint32_t clust = write_file(child_path, st.st_size);
            add_root_entry(ent->d_name, 0x20, clust, st.st_size, st.st_mtime);
        }
    }
    closedir(d);
}

static void populate_subdir(uint32_t dir_cluster, uint32_t *dir_used,
                            const char *src_path)
{
    DIR *d = opendir(src_path);
    if (!d) { perror(src_path); exit(1); }

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;

        validate_user_name(ent->d_name);

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, ent->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) { perror(child_path); exit(1); }

        if (S_ISDIR(st.st_mode)) {
            uint32_t clust = alloc_clusters(1);
            memset(image + cluster_offset(clust), 0, CLUSTER_SIZE);
            add_subdir_entry(dir_cluster, dir_used, ent->d_name, 0x10,
                             clust, 0, st.st_mtime);

            uint32_t sub_used = 0;
            add_subdir_entry(clust, &sub_used, ".", 0x10, clust, 0, st.st_mtime);
            add_subdir_entry(clust, &sub_used, "..", 0x10, dir_cluster, 0, st.st_mtime);
            populate_subdir(clust, &sub_used, child_path);
        } else if (S_ISREG(st.st_mode)) {
            uint32_t clust = write_file(child_path, st.st_size);
            add_subdir_entry(dir_cluster, dir_used, ent->d_name, 0x20,
                             clust, st.st_size, st.st_mtime);
        }
    }
    closedir(d);
}

int main(int argc, char **argv)
{
    char *populate_dir = NULL;
    int size_kb = DEFAULT_SIZE_KB;

    int opt;
    while ((opt = getopt(argc, argv, "d:s:")) != -1) {
        switch (opt) {
        case 'd': populate_dir = optarg; break;
        case 's': size_kb = atoi(optarg); break;
        default:
            fprintf(stderr, "Usage: %s [-d directory] [-s size_kb] <output>\n", argv[0]);
            return 1;
        }
    }
    if (optind >= argc) {
        fprintf(stderr, "Usage: %s [-d directory] [-s size_kb] <output>\n", argv[0]);
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
    total_sectors = image_size / SECTOR_SIZE;

    /* FAT12 sizing */
    root_dir_sectors = (ROOT_DIR_ENTRIES * 32 + SECTOR_SIZE - 1) / SECTOR_SIZE;
    uint32_t reserved_sectors = 1; /* boot sector */
    if (total_sectors <= reserved_sectors + root_dir_sectors + NUM_FATS + 2)
        die("filesystem too small");
    uint32_t data_sectors = total_sectors - reserved_sectors - root_dir_sectors;

    /* Compute sectors per FAT: each FAT12 entry is 1.5 bytes */
    /* data_sectors = total_clusters * SPC + NUM_FATS * spf */
    /* Solve: total_clusters = (data_sectors - NUM_FATS * spf) / SPC */
    /* Each FAT sector covers SECTOR_SIZE * 2 / 3 entries */
    sectors_per_fat = 1;
    while (1) {
        uint32_t avail = data_sectors - NUM_FATS * sectors_per_fat;
        total_clusters = avail / SECTORS_PER_CLUSTER;
        uint32_t fat_entries_needed = total_clusters + 2;
        uint32_t fat_bytes = (fat_entries_needed * 3 + 1) / 2;
        uint32_t spf_needed = (fat_bytes + SECTOR_SIZE - 1) / SECTOR_SIZE;
        if (spf_needed <= sectors_per_fat) break;
        sectors_per_fat = spf_needed;
    }

    if (total_clusters > FAT12_MAX_CLUSTERS)
        total_clusters = FAT12_MAX_CLUSTERS;

    data_start = reserved_sectors + NUM_FATS * sectors_per_fat + root_dir_sectors;

    /* Allocate */
    image = calloc(1, image_size);
    fat = calloc(total_clusters + 2, sizeof(uint16_t));
    if (!image || !fat) die("cannot allocate memory");

    /* Reserve FAT entries 0 and 1 */
    fat[0] = 0xF00 | MEDIA_BYTE;  /* media byte in low 8 bits */
    fat[1] = 0xFFF;
    next_cluster = 2;
    root_dir_used = 0;

    /* Write boot sector / BPB */
    image[0x00] = 0x60;           /* 68000 BRA.S */
    image[0x01] = 0x38;           /* branch offset (skip BPB) */
    memcpy(image + 0x02, "GEMDOS", 6);  /* OEM */
    /* Serial number: 3 bytes at 0x08-0x0A, big-endian Atari convention */
    uint32_t serial = (uint32_t)time(NULL) & 0xFFFFFF;
    image[0x08] = (serial >> 16) & 0xFF;
    image[0x09] = (serial >>  8) & 0xFF;
    image[0x0A] =  serial        & 0xFF;

    /* BPB fields - Atari uses big-endian for BPS */
    put_be16(image + 0x0B, SECTOR_SIZE);          /* BPS (big-endian!) */
    image[0x0D] = SECTORS_PER_CLUSTER;             /* SPC */
    put_le16(image + 0x0E, reserved_sectors);      /* RES */
    image[0x10] = NUM_FATS;                        /* NFATS */
    put_le16(image + 0x11, ROOT_DIR_ENTRIES);      /* NDIRS */
    put_le16(image + 0x13, total_sectors);         /* NSECTS */
    image[0x15] = MEDIA_BYTE;                      /* MEDIA */
    put_le16(image + 0x16, sectors_per_fat);       /* SPF */
    put_le16(image + 0x18, 9);                     /* SPT (9 for 720KB) */
    put_le16(image + 0x1A, 2);                     /* NHEADS */
    put_le16(image + 0x1C, 0);                     /* NHID */

    /* Populate from directory */
    if (populate_dir)
        populate_root(populate_dir);

    /* Write FATs */
    write_fat(reserved_sectors);
    write_fat(reserved_sectors + sectors_per_fat);

    /* Fix checksum so BE16 word sum == 0x1234 */
    fix_checksum();

    /* Write image */
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) { perror("open"); return 1; }
    if ((size_t)write(fd, image, image_size) != image_size) {
        perror("write"); return 1;
    }
    close(fd);

    printf("Created GEMDOS image: %s (%dKB, %u clusters, FAT12, checksum=0x1234)\n",
           filename, size_kb, total_clusters);

    free(image);
    free(fat);
    return 0;
}

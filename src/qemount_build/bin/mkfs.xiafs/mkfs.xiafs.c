/*
 * Minimal xiafs filesystem image creator
 * Based on Q. Frank Xia's original mkxfs.c (1992) and the modern-xiafs
 * kernel module header by Jeremy Bingham (2013).
 *
 * Creates xiafs filesystem images for testing, optionally populated from a
 * directory tree via -d. Xiafs was an early Linux filesystem (1993-1997)
 * based on Minix, competing with ext2.
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

#define BLOCK_SIZE          1024
#define XIAFS_SUPER_MAGIC   0x012FD16D
#define XIAFS_ROOT_INO      1
#define XIAFS_BAD_INO       2
#define XIAFS_NAME_LEN      248
#define XIAFS_NUM_ZONES     10
#define XIAFS_DIRECT_ZONES  8
#define INODES_PER_BLOCK    (BLOCK_SIZE / 64)  /* 16 */
#define ADDRS_PER_ZONE      (BLOCK_SIZE / 4)   /* 256 */

#define UPPER(a, b) (((a) + (b) - 1) / (b))

/* On-disk superblock (second half of block 0, after 512-byte boot sector) */
struct xiafs_super_block {
    uint8_t  s_boot[512];       /* boot sector */
    uint32_t s_zone_size;
    uint32_t s_nzones;
    uint32_t s_ninodes;
    uint32_t s_ndatazones;
    uint32_t s_imap_zones;
    uint32_t s_zmap_zones;
    uint32_t s_firstdatazone;
    uint32_t s_zone_shift;
    uint32_t s_max_size;
    uint32_t s_reserved[4];
    uint32_t s_firstkernzone;
    uint32_t s_kernzones;
    uint32_t s_magic;
};

/* On-disk inode - 64 bytes, 16 per block */
struct xiafs_inode {
    uint16_t i_mode;
    uint16_t i_nlinks;
    uint16_t i_uid;
    uint16_t i_gid;
    uint32_t i_size;
    uint32_t i_ctime;
    uint32_t i_atime;
    uint32_t i_mtime;
    uint32_t i_zone[XIAFS_NUM_ZONES];
};

/* Directory entry */
struct xiafs_direct {
    uint32_t d_ino;
    uint16_t d_rec_len;
    uint8_t  d_name_len;
    char     d_name[XIAFS_NAME_LEN + 1];
};

#define DIR_REC_LEN(name_len) (((7 + (name_len) + 3) / 4) * 4)

/* Global state */
static int       fs_fd;
static uint32_t  fs_nzones;
static uint32_t  fs_ninodes;
static uint32_t  fs_imap_zones;
static uint32_t  fs_zmap_zones;
static uint32_t  fs_inode_zones;
static uint32_t  fs_firstdatazone;
static uint32_t  fs_ndatazones;
static uint32_t  fs_now;

static struct xiafs_inode *inode_table;
static uint8_t *inode_bitmap;
static uint8_t *zone_bitmap;

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.xiafs: %s\n", msg);
    exit(1);
}

static void write_at(off_t offset, const void *buf, size_t len)
{
    if (lseek(fs_fd, offset, SEEK_SET) != offset) { perror("lseek"); exit(1); }
    if ((size_t)write(fs_fd, buf, len) != len) { perror("write"); exit(1); }
}

static void write_block(uint32_t block, const void *buf)
{
    write_at((off_t)block * BLOCK_SIZE, buf, BLOCK_SIZE);
}

static void read_block(uint32_t block, void *buf)
{
    if (lseek(fs_fd, (off_t)block * BLOCK_SIZE, SEEK_SET) < 0) { perror("lseek"); exit(1); }
    if ((size_t)read(fs_fd, buf, BLOCK_SIZE) != BLOCK_SIZE) { perror("read"); exit(1); }
}

/* Bitmap operations */
static void set_bit(uint8_t *bitmap, uint32_t bit)
{
    bitmap[bit / 8] |= (1 << (bit % 8));
}

static int test_bit(uint8_t *bitmap, uint32_t bit)
{
    return bitmap[bit / 8] & (1 << (bit % 8));
}

static uint32_t alloc_zone(void)
{
    for (uint32_t z = fs_firstdatazone; z < fs_nzones; z++) {
        if (!test_bit(zone_bitmap, z)) {
            set_bit(zone_bitmap, z);
            return z;
        }
    }
    die("no free zones");
    return 0;
}

static uint32_t alloc_inode(void)
{
    for (uint32_t i = 1; i <= fs_ninodes; i++) {
        if (!test_bit(inode_bitmap, i)) {
            set_bit(inode_bitmap, i);
            return i;
        }
    }
    die("no free inodes");
    return 0;
}

/* Set a direct zone pointer for an inode, preserving the block-count high
 * byte on zones 0-2. Indirect zones are managed by the caller. */
static void inode_set_zone(struct xiafs_inode *inode, uint32_t file_zone,
                           uint32_t disk_zone)
{
    if (file_zone >= XIAFS_DIRECT_ZONES)
        die("inode_set_zone: indirect zones must be handled by caller");
    if (file_zone < 3)
        inode->i_zone[file_zone] = (inode->i_zone[file_zone] & 0xFF000000) | disk_zone;
    else
        inode->i_zone[file_zone] = disk_zone;
}

/* Set block count in high bytes of zone pointers 0-2 */
static void inode_set_blocks(struct xiafs_inode *inode, uint32_t blocks)
{
    inode->i_zone[0] = (inode->i_zone[0] & 0x00FFFFFF) | ((blocks << 24) & 0xFF000000);
    inode->i_zone[1] = (inode->i_zone[1] & 0x00FFFFFF) | ((blocks << 16) & 0xFF000000);
    inode->i_zone[2] = (inode->i_zone[2] & 0x00FFFFFF) | ((blocks <<  8) & 0xFF000000);
}

/* Directory operations */
static void init_dir_block(uint32_t block, uint32_t self_ino, uint32_t parent_ino)
{
    char buf[BLOCK_SIZE];
    memset(buf, 0, BLOCK_SIZE);

    uint16_t dot_len = DIR_REC_LEN(1);

    struct xiafs_direct *dot = (struct xiafs_direct *)buf;
    dot->d_ino = self_ino;
    dot->d_rec_len = dot_len;
    dot->d_name_len = 1;
    dot->d_name[0] = '.';

    struct xiafs_direct *dotdot = (struct xiafs_direct *)(buf + dot_len);
    dotdot->d_ino = parent_ino;
    dotdot->d_rec_len = BLOCK_SIZE - dot_len;
    dotdot->d_name_len = 2;
    dotdot->d_name[0] = '.';
    dotdot->d_name[1] = '.';

    write_block(block, buf);
}

static void add_dir_entry(uint32_t dir_ino, const char *name, uint32_t child_ino)
{
    struct xiafs_inode *dir = &inode_table[dir_ino - 1];
    uint8_t name_len = strlen(name);
    uint16_t need = DIR_REC_LEN(name_len);
    uint32_t n_blocks = UPPER(dir->i_size, BLOCK_SIZE);

    for (uint32_t b = 0; b < n_blocks; b++) {
        uint32_t disk_block = dir->i_zone[b] & 0x00FFFFFF;
        char buf[BLOCK_SIZE];
        read_block(disk_block, buf);

        uint32_t off = 0;
        while (off < BLOCK_SIZE) {
            struct xiafs_direct *de = (struct xiafs_direct *)(buf + off);
            uint16_t actual_len = DIR_REC_LEN(de->d_name_len);
            uint16_t slack = de->d_rec_len - actual_len;

            if (slack >= need) {
                de->d_rec_len = actual_len;
                struct xiafs_direct *new_de = (struct xiafs_direct *)(buf + off + actual_len);
                new_de->d_ino = child_ino;
                new_de->d_rec_len = slack;
                new_de->d_name_len = name_len;
                memcpy(new_de->d_name, name, name_len);
                write_block(disk_block, buf);
                return;
            }
            off += de->d_rec_len;
        }
    }

    /* Need a new block */
    uint32_t new_block = alloc_zone();
    uint32_t block_idx = n_blocks;
    if (block_idx >= XIAFS_DIRECT_ZONES)
        die("directory too large");
    inode_set_zone(dir, block_idx, new_block);
    dir->i_size = (block_idx + 1) * BLOCK_SIZE;

    char buf[BLOCK_SIZE];
    memset(buf, 0, BLOCK_SIZE);
    struct xiafs_direct *de = (struct xiafs_direct *)buf;
    de->d_ino = child_ino;
    de->d_rec_len = BLOCK_SIZE;
    de->d_name_len = name_len;
    memcpy(de->d_name, name, name_len);
    write_block(new_block, buf);
}

static void write_file_data(uint32_t ino, const char *src_path)
{
    int src = open(src_path, O_RDONLY);
    if (src < 0) { perror(src_path); exit(1); }

    struct stat st;
    if (fstat(src, &st) < 0) { perror(src_path); exit(1); }

    struct xiafs_inode *inode = &inode_table[ino - 1];
    inode->i_size = st.st_size;

    uint32_t indirect[ADDRS_PER_ZONE] = {0};
    int have_indirect = 0;
    uint32_t file_zone = 0;
    uint32_t blocks = 0;

    for (;;) {
        char buf[BLOCK_SIZE];
        memset(buf, 0, BLOCK_SIZE);
        ssize_t n = read(src, buf, BLOCK_SIZE);
        if (n < 0) { perror(src_path); exit(1); }
        if (n == 0) break;

        uint32_t disk_zone = alloc_zone();
        write_block(disk_zone, buf);

        if (file_zone < XIAFS_DIRECT_ZONES) {
            inode_set_zone(inode, file_zone, disk_zone);
        } else {
            uint32_t idx = file_zone - XIAFS_DIRECT_ZONES;
            if (idx >= ADDRS_PER_ZONE)
                die("file too large (needs double indirect)");
            indirect[idx] = disk_zone;
            have_indirect = 1;
        }

        file_zone++;
        blocks++;
    }
    close(src);

    if (have_indirect) {
        inode->i_zone[8] = alloc_zone();
        write_block(inode->i_zone[8], indirect);
    }

    inode_set_blocks(inode, blocks);
}

static void populate_dir(uint32_t dir_ino, const char *src_path)
{
    DIR *d = opendir(src_path);
    if (!d) { perror(src_path); exit(1); }

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;

        if (strlen(ent->d_name) > XIAFS_NAME_LEN) {
            fprintf(stderr, "mkfs.xiafs: name too long (max %d): %s\n",
                    XIAFS_NAME_LEN, ent->d_name);
            exit(1);
        }

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, ent->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) { perror(child_path); exit(1); }
        if (!S_ISREG(st.st_mode) && !S_ISDIR(st.st_mode))
            continue;

        uint32_t child_ino = alloc_inode();
        struct xiafs_inode *child = &inode_table[child_ino - 1];
        child->i_mode = st.st_mode;
        child->i_uid = 0;
        child->i_gid = 0;
        child->i_ctime = child->i_atime = child->i_mtime = fs_now;

        if (S_ISDIR(st.st_mode)) {
            uint32_t block = alloc_zone();
            child->i_nlinks = 2;
            child->i_size = BLOCK_SIZE;
            inode_set_zone(child, 0, block);
            inode_set_blocks(child, 1);
            init_dir_block(block, child_ino, dir_ino);
            add_dir_entry(dir_ino, ent->d_name, child_ino);
            inode_table[dir_ino - 1].i_nlinks++;
            populate_dir(child_ino, child_path);
        } else {
            child->i_nlinks = 1;
            add_dir_entry(dir_ino, ent->d_name, child_ino);
            write_file_data(child_ino, child_path);
        }
    }
    closedir(d);
}

int main(int argc, char **argv)
{
    char *populate_path = NULL;
    int size_mb = 2;

    int opt;
    while ((opt = getopt(argc, argv, "d:")) != -1) {
        if (opt == 'd')
            populate_path = optarg;
        else {
            fprintf(stderr, "Usage: %s [-d directory] <filename> <size_in_MB>\n", argv[0]);
            return 1;
        }
    }
    if (optind + 2 != argc) {
        fprintf(stderr, "Usage: %s [-d directory] <filename> <size_in_MB>\n", argv[0]);
        return 1;
    }

    char *filename = argv[optind];
    size_mb = atoi(argv[optind + 1]);
    if (size_mb <= 0)
        die("size must be positive");
    fs_nzones = (uint32_t)((uint64_t)size_mb * 1024 * 1024 / BLOCK_SIZE);
    fs_now = time(NULL);

    if (fs_nzones < 32)
        die("filesystem too small");
    if (fs_nzones >= (1u << 24))
        die("filesystem exceeds 16 GB zone-number limit");

    /* Compute layout (matching original mkxfs logic) */
    fs_inode_zones = ((fs_nzones >> 2) / INODES_PER_BLOCK) + 1;
    fs_ninodes = fs_inode_zones * INODES_PER_BLOCK;
    fs_imap_zones = fs_ninodes / (BLOCK_SIZE * 8) + 1;
    fs_zmap_zones = fs_nzones / (BLOCK_SIZE * 8) + 1;
    fs_firstdatazone = 1 + fs_imap_zones + fs_zmap_zones + fs_inode_zones;
    fs_ndatazones = fs_nzones - fs_firstdatazone;

    /* Max file size: (ADDRS_PER_ZONE + 1) * ADDRS_PER_ZONE + 8 zones */
    uint32_t max_size = ((ADDRS_PER_ZONE + 1) * ADDRS_PER_ZONE + XIAFS_DIRECT_ZONES) * BLOCK_SIZE;

    /* Allocate bitmaps and inode table */
    size_t imap_bytes = fs_imap_zones * BLOCK_SIZE;
    size_t zmap_bytes = fs_zmap_zones * BLOCK_SIZE;
    size_t itable_bytes = fs_inode_zones * BLOCK_SIZE;

    inode_bitmap = calloc(1, imap_bytes);
    zone_bitmap = calloc(1, zmap_bytes);
    inode_table = calloc(1, itable_bytes);
    if (!inode_bitmap || !zone_bitmap || !inode_table)
        die("cannot allocate memory");

    /* Mark system zones as used in zone bitmap */
    for (uint32_t z = 0; z < fs_firstdatazone; z++)
        set_bit(zone_bitmap, z);

    /* Create and truncate image */
    fs_fd = open(filename, O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fs_fd < 0) { perror("open"); return 1; }
    if (ftruncate(fs_fd, (off_t)fs_nzones * BLOCK_SIZE) < 0) { perror("ftruncate"); return 1; }

    /* Set up root inode (inode 1) */
    set_bit(inode_bitmap, XIAFS_ROOT_INO);
    uint32_t root_block = alloc_zone();
    struct xiafs_inode *root = &inode_table[XIAFS_ROOT_INO - 1];
    root->i_mode = S_IFDIR | 0755;
    root->i_nlinks = 2;
    root->i_size = BLOCK_SIZE;
    root->i_ctime = root->i_atime = root->i_mtime = fs_now;
    inode_set_zone(root, 0, root_block);
    inode_set_blocks(root, 1);
    init_dir_block(root_block, XIAFS_ROOT_INO, XIAFS_ROOT_INO);

    /* Reserve bad blocks inode (inode 2) */
    set_bit(inode_bitmap, XIAFS_BAD_INO);
    struct xiafs_inode *bad = &inode_table[XIAFS_BAD_INO - 1];
    bad->i_mode = S_IFREG;
    bad->i_nlinks = 1;
    bad->i_ctime = bad->i_atime = bad->i_mtime = fs_now;

    /* Populate from directory */
    if (populate_path)
        populate_dir(XIAFS_ROOT_INO, populate_path);

    /* Write superblock */
    struct xiafs_super_block sb;
    memset(&sb, 0, sizeof(sb));
    sb.s_zone_size = BLOCK_SIZE;
    sb.s_nzones = fs_nzones;
    sb.s_ninodes = fs_ninodes;
    sb.s_ndatazones = fs_ndatazones;
    sb.s_imap_zones = fs_imap_zones;
    sb.s_zmap_zones = fs_zmap_zones;
    sb.s_firstdatazone = fs_firstdatazone;
    sb.s_zone_shift = 0;
    sb.s_max_size = max_size;
    sb.s_firstkernzone = fs_firstdatazone;
    sb.s_kernzones = 0;
    sb.s_magic = XIAFS_SUPER_MAGIC;
    write_block(0, &sb);

    /* Write inode bitmap */
    for (uint32_t i = 0; i < fs_imap_zones; i++)
        write_block(1 + i, inode_bitmap + i * BLOCK_SIZE);

    /* Write zone bitmap */
    for (uint32_t i = 0; i < fs_zmap_zones; i++)
        write_block(1 + fs_imap_zones + i, zone_bitmap + i * BLOCK_SIZE);

    /* Write inode table */
    for (uint32_t i = 0; i < fs_inode_zones; i++)
        write_block(1 + fs_imap_zones + fs_zmap_zones + i,
                    (uint8_t *)inode_table + i * BLOCK_SIZE);

    close(fs_fd);
    free(inode_bitmap);
    free(zone_bitmap);
    free(inode_table);

    printf("Created xiafs image: %s (%dMB, %u inodes, %u zones, magic=0x%X)\n",
           filename, size_mb, fs_ninodes, fs_nzones, XIAFS_SUPER_MAGIC);
    printf("First data zone: %u, data zones: %u\n", fs_firstdatazone, fs_ndatazones);

    return 0;
}

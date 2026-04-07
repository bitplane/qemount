/*
 * Minimal ext (original extended filesystem) creator
 * Based on Linux 1.0 include/linux/ext_fs.h and efsprogs mkefs.c
 * by Remy Card (card@masi.ibp.fr), 1992-1993
 *
 * Creates ext filesystem images for testing, optionally populated from a
 * directory tree via -d. The ext filesystem was the first filesystem written
 * specifically for Linux, superseding the Minix filesystem in 1992 and itself
 * replaced by ext2 in 1993.
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

#define BLOCK_SIZE 1024
#define EXT_SUPER_MAGIC 0x137D
#define EXT_ROOT_INO 1
#define EXT_NAME_LEN 255
#define EXT_DIR_PAD 8
#define INODES_PER_BLOCK (BLOCK_SIZE / sizeof(struct ext_inode))
#define PTRS_PER_BLOCK (BLOCK_SIZE / sizeof(uint32_t))  /* 256 */
#define DIRECT_BLOCKS 9

/* On-disk inode - 64 bytes, 16 per block */
struct ext_inode {
    uint16_t i_mode;
    uint16_t i_uid;
    uint32_t i_size;
    uint32_t i_time;
    uint16_t i_gid;
    uint16_t i_nlinks;
    uint32_t i_zone[12];   /* 9 direct, 1 indirect, 1 double, 1 triple */
};

/* Free block list node - stored in the free blocks themselves */
struct ext_free_block {
    uint32_t count;
    uint32_t free[254];
    uint32_t next;
};

/* Free inode list node - stored in unused inode table slots */
struct ext_free_inode {
    uint32_t count;
    uint32_t free[14];
    uint32_t next;
};

/* Superblock at block 1 (offset 1024) */
struct ext_super_block {
    uint32_t s_ninodes;
    uint32_t s_nzones;
    uint32_t s_firstfreeblock;
    uint32_t s_freeblockscount;
    uint32_t s_firstfreeinode;
    uint32_t s_freeinodescount;
    uint32_t s_firstdatazone;
    uint32_t s_log_zone_size;
    uint32_t s_max_size;
    uint32_t s_reserved[5];
    uint16_t s_magic;
};

/* Directory entry - variable length, 8-byte aligned */
struct ext_dir_entry {
    uint32_t inode;
    uint16_t rec_len;
    uint16_t name_len;
    char name[EXT_NAME_LEN];
};

#define UPPER(size, n) (((size) + ((n) - 1)) / (n))
#define DIR_REC_LEN(name_len) (((8 + (name_len) + EXT_DIR_PAD - 1) / EXT_DIR_PAD) * EXT_DIR_PAD)

/* Global filesystem state */
static int fs_fd;
static uint32_t fs_total_blocks;
static uint32_t fs_ninodes;
static uint32_t fs_firstdatazone;
static uint32_t fs_now;
static struct ext_inode *fs_inodes;  /* in-memory inode table */
static uint8_t *block_bitmap;       /* 1 = used */
static uint8_t *inode_bitmap;       /* 1 = used */

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.ext: %s\n", msg);
    exit(1);
}

static void write_at(off_t offset, const void *buf, size_t len)
{
    if (lseek(fs_fd, offset, SEEK_SET) != offset) {
        perror("lseek");
        exit(1);
    }
    if ((size_t)write(fs_fd, buf, len) != len) {
        perror("write");
        exit(1);
    }
}

static void write_block(uint32_t block, const void *buf)
{
    write_at((off_t)block * BLOCK_SIZE, buf, BLOCK_SIZE);
}

/* ---- Bitmap-based allocators ---- */

static uint32_t alloc_block(void)
{
    for (uint32_t b = fs_firstdatazone; b < fs_total_blocks; b++) {
        if (!block_bitmap[b]) {
            block_bitmap[b] = 1;
            return b;
        }
    }
    die("no free blocks");
    return 0;
}

static uint32_t alloc_inode(void)
{
    for (uint32_t i = 1; i <= fs_ninodes; i++) {
        if (!inode_bitmap[i]) {
            inode_bitmap[i] = 1;
            return i;
        }
    }
    die("no free inodes");
    return 0;
}

/* ---- Block assignment for file data ---- */

static void inode_set_block(struct ext_inode *inode, uint32_t file_block,
                            uint32_t disk_block)
{
    if (file_block < DIRECT_BLOCKS) {
        inode->i_zone[file_block] = disk_block;
        return;
    }

    /* Single indirect */
    file_block -= DIRECT_BLOCKS;
    if (file_block < PTRS_PER_BLOCK) {
        if (!inode->i_zone[9]) {
            inode->i_zone[9] = alloc_block();
            char zero[BLOCK_SIZE] = {0};
            write_block(inode->i_zone[9], zero);
        }
        uint32_t buf[PTRS_PER_BLOCK];
        lseek(fs_fd, (off_t)inode->i_zone[9] * BLOCK_SIZE, SEEK_SET);
        read(fs_fd, buf, BLOCK_SIZE);
        buf[file_block] = disk_block;
        write_block(inode->i_zone[9], buf);
        return;
    }

    die("file too large (needs double indirect)");
}

/* ---- Directory operations ---- */

static void init_dir_block(uint32_t block, uint32_t self_ino, uint32_t parent_ino)
{
    char buf[BLOCK_SIZE];
    memset(buf, 0, BLOCK_SIZE);

    struct ext_dir_entry *dot = (struct ext_dir_entry *)buf;
    dot->inode = self_ino;
    dot->rec_len = DIR_REC_LEN(1);
    dot->name_len = 1;
    dot->name[0] = '.';

    struct ext_dir_entry *dotdot = (struct ext_dir_entry *)(buf + dot->rec_len);
    dotdot->inode = parent_ino;
    dotdot->rec_len = BLOCK_SIZE - dot->rec_len;  /* fill remainder */
    dotdot->name_len = 2;
    dotdot->name[0] = '.';
    dotdot->name[1] = '.';

    write_block(block, buf);
}

static void add_dir_entry(uint32_t dir_ino, const char *name, uint32_t child_ino)
{
    struct ext_inode *dir = &fs_inodes[dir_ino - 1];
    uint16_t name_len = strlen(name);
    uint16_t need = DIR_REC_LEN(name_len);

    /* Find the last block of the directory */
    uint32_t n_blocks = UPPER(dir->i_size, BLOCK_SIZE);

    for (uint32_t b = 0; b < n_blocks; b++) {
        /* Read the block - only direct blocks for directories */
        uint32_t disk_block = dir->i_zone[b];
        char buf[BLOCK_SIZE];
        lseek(fs_fd, (off_t)disk_block * BLOCK_SIZE, SEEK_SET);
        read(fs_fd, buf, BLOCK_SIZE);

        /* Walk entries to find the last one */
        uint32_t off = 0;
        while (off < BLOCK_SIZE) {
            struct ext_dir_entry *de = (struct ext_dir_entry *)(buf + off);
            uint16_t actual_len = DIR_REC_LEN(de->name_len);
            uint16_t slack = de->rec_len - actual_len;

            if (slack >= need) {
                /* Split this entry: shrink it, add new entry in the slack */
                de->rec_len = actual_len;
                struct ext_dir_entry *new_de = (struct ext_dir_entry *)(buf + off + actual_len);
                new_de->inode = child_ino;
                new_de->rec_len = slack;
                new_de->name_len = name_len;
                memcpy(new_de->name, name, name_len);
                write_block(disk_block, buf);
                return;
            }
            off += de->rec_len;
        }
    }

    /* Need a new block */
    uint32_t new_block = alloc_block();
    uint32_t block_idx = n_blocks;
    if (block_idx >= DIRECT_BLOCKS)
        die("directory too large");
    dir->i_zone[block_idx] = new_block;
    dir->i_size = (block_idx + 1) * BLOCK_SIZE;

    char buf[BLOCK_SIZE];
    memset(buf, 0, BLOCK_SIZE);
    struct ext_dir_entry *de = (struct ext_dir_entry *)buf;
    de->inode = child_ino;
    de->rec_len = BLOCK_SIZE;  /* fills entire block */
    de->name_len = name_len;
    memcpy(de->name, name, name_len);
    write_block(new_block, buf);
}

/* ---- File writing ---- */

static void write_file_data(uint32_t ino, const char *src_path)
{
    struct stat st;
    if (stat(src_path, &st) < 0) { perror(src_path); return; }

    struct ext_inode *inode = &fs_inodes[ino - 1];
    inode->i_size = st.st_size;

    if (st.st_size == 0) return;

    int src = open(src_path, O_RDONLY);
    if (src < 0) { perror(src_path); return; }

    uint32_t remaining = st.st_size;
    uint32_t file_block = 0;
    while (remaining > 0) {
        char buf[BLOCK_SIZE];
        memset(buf, 0, BLOCK_SIZE);
        ssize_t n = read(src, buf, BLOCK_SIZE);
        if (n <= 0) break;

        uint32_t disk_block = alloc_block();
        inode_set_block(inode, file_block, disk_block);
        write_block(disk_block, buf);

        file_block++;
        remaining -= n;
    }
    close(src);
}

/* ---- Recursive directory population ---- */

static void populate_dir(uint32_t dir_ino, const char *src_path)
{
    DIR *d = opendir(src_path);
    if (!d) { perror(src_path); return; }

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, ent->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) { perror(child_path); continue; }

        /* Skip non-regular, non-directory entries */
        if (!S_ISREG(st.st_mode) && !S_ISDIR(st.st_mode))
            continue;

        uint32_t child_ino = alloc_inode();
        struct ext_inode *child = &fs_inodes[child_ino - 1];
        child->i_mode = st.st_mode;
        child->i_time = fs_now;

        if (S_ISDIR(st.st_mode)) {
            uint32_t block = alloc_block();
            child->i_zone[0] = block;
            child->i_nlinks = 2;
            child->i_size = BLOCK_SIZE;
            init_dir_block(block, child_ino, dir_ino);
            add_dir_entry(dir_ino, ent->d_name, child_ino);
            fs_inodes[dir_ino - 1].i_nlinks++;
            populate_dir(child_ino, child_path);
        } else {
            child->i_nlinks = 1;
            add_dir_entry(dir_ino, ent->d_name, child_ino);
            write_file_data(child_ino, child_path);
        }
    }
    closedir(d);
}

/* ---- Free list builders (from unallocated bitmap entries) ---- */

static void build_free_block_list(struct ext_super_block *sb)
{
    uint32_t count = 0;
    uint32_t next_chain = 0;

    struct ext_free_block efb;
    memset(&efb, 0, sizeof(efb));
    uint32_t pending = 0;

    for (uint32_t blk = fs_total_blocks - 1; blk >= fs_firstdatazone; blk--) {
        if (block_bitmap[blk]) continue;
        if (!pending) {
            pending = blk;
        } else {
            efb.free[efb.count++] = blk;
        }
        if (efb.count == 254) {
            efb.next = next_chain;
            count += efb.count + 1;
            write_block(pending, &efb);
            block_bitmap[pending] = 1;  /* now used by free list */
            next_chain = pending;
            pending = 0;
            memset(&efb, 0, sizeof(efb));
        }
    }
    if (pending) {
        efb.next = next_chain;
        count += efb.count + 1;
        write_block(pending, &efb);
        block_bitmap[pending] = 1;
        next_chain = pending;
    }
    sb->s_firstfreeblock = next_chain;
    sb->s_freeblockscount = count;
}

static void build_free_inode_list(struct ext_super_block *sb)
{
    uint32_t count = 0;
    uint32_t next_chain = 0;
    uint32_t head = 0;

    struct ext_free_inode *efi = NULL;
    for (uint32_t ino = fs_ninodes; ino >= 1; ino--) {
        if (inode_bitmap[ino]) continue;
        if (!efi) {
            efi = (struct ext_free_inode *)&fs_inodes[ino - 1];
            memset(efi, 0, sizeof(*efi));
            efi->next = next_chain;
            head = ino;
            next_chain = ino;
        } else {
            efi->free[efi->count++] = ino;
        }
        if (efi->count == 14) {
            count += efi->count + 1;
            efi = NULL;
        }
    }
    if (efi)
        count += efi->count + 1;

    sb->s_firstfreeinode = head;
    sb->s_freeinodescount = count;
}

/* ---- Main ---- */

int main(int argc, char **argv)
{
    char *populate_dir_path = NULL;

    /* Parse -d option */
    int opt;
    while ((opt = getopt(argc, argv, "d:")) != -1) {
        if (opt == 'd')
            populate_dir_path = optarg;
        else {
            fprintf(stderr, "Usage: %s [-d directory] <filename> <size_in_MB>\n",
                    argv[0]);
            return 1;
        }
    }
    if (optind + 2 != argc) {
        fprintf(stderr, "Usage: %s [-d directory] <filename> <size_in_MB>\n",
                argv[0]);
        return 1;
    }

    char *filename = argv[optind];
    int size_mb = atoi(argv[optind + 1]);
    fs_total_blocks = (size_mb * 1024 * 1024) / BLOCK_SIZE;
    fs_now = time(NULL);

    if (fs_total_blocks < 16) {
        fprintf(stderr, "Filesystem too small (need at least 16 blocks)\n");
        return 1;
    }

    /* Compute layout */
    fs_ninodes = (fs_total_blocks * BLOCK_SIZE) / 4096;
    if (fs_ninodes % INODES_PER_BLOCK)
        fs_ninodes = ((fs_ninodes / INODES_PER_BLOCK) + 1) * INODES_PER_BLOCK;
    uint32_t inode_blocks = UPPER(fs_ninodes, INODES_PER_BLOCK);
    fs_firstdatazone = 2 + inode_blocks;

    /* Allocate bitmaps */
    block_bitmap = calloc(fs_total_blocks, 1);
    inode_bitmap = calloc(fs_ninodes + 1, 1);  /* 1-indexed */
    if (!block_bitmap || !inode_bitmap) die("cannot allocate bitmaps");

    /* Mark system blocks as used (boot + super + inode table) */
    for (uint32_t b = 0; b < fs_firstdatazone; b++)
        block_bitmap[b] = 1;

    /* Create and truncate image */
    fs_fd = open(filename, O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fs_fd < 0) { perror("open"); return 1; }
    ftruncate(fs_fd, size_mb * 1024 * 1024);

    /* Allocate in-memory inode table */
    size_t inode_buf_size = inode_blocks * BLOCK_SIZE;
    fs_inodes = calloc(1, inode_buf_size);
    if (!fs_inodes) die("cannot allocate inode table");

    /* Set up root inode */
    inode_bitmap[EXT_ROOT_INO] = 1;
    uint32_t root_block = alloc_block();
    struct ext_inode *root = &fs_inodes[EXT_ROOT_INO - 1];
    root->i_mode = S_IFDIR | 0755;
    root->i_nlinks = 2;
    root->i_time = fs_now;
    root->i_size = BLOCK_SIZE;
    root->i_zone[0] = root_block;
    init_dir_block(root_block, EXT_ROOT_INO, EXT_ROOT_INO);

    /* Populate from directory if requested */
    if (populate_dir_path)
        populate_dir(EXT_ROOT_INO, populate_dir_path);

    /* Build free lists from remaining unallocated blocks/inodes */
    char sb_buf[BLOCK_SIZE];
    memset(sb_buf, 0, BLOCK_SIZE);
    struct ext_super_block *sb = (struct ext_super_block *)sb_buf;
    sb->s_ninodes = fs_ninodes;
    sb->s_nzones = fs_total_blocks;
    sb->s_firstdatazone = fs_firstdatazone;
    sb->s_log_zone_size = 0;
    sb->s_max_size = (1u << 31) - 1;
    sb->s_magic = EXT_SUPER_MAGIC;

    build_free_block_list(sb);
    build_free_inode_list(sb);

    /* Write superblock and inode table */
    write_at(BLOCK_SIZE, sb_buf, BLOCK_SIZE);
    write_at(2 * BLOCK_SIZE, fs_inodes, inode_buf_size);

    close(fs_fd);
    free(fs_inodes);
    free(block_bitmap);
    free(inode_bitmap);

    printf("Created ext image: %s (%dMB, %u inodes, %u blocks, magic=0x%x)\n",
           filename, size_mb, fs_ninodes, fs_total_blocks, EXT_SUPER_MAGIC);
    printf("First data zone: %u, free blocks: %u, free inodes: %u\n",
           fs_firstdatazone, sb->s_freeblockscount, sb->s_freeinodescount);

    return 0;
}

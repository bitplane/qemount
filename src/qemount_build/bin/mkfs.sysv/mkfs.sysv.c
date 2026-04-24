/*
 * Minimal SVR4 filesystem creator.
 *
 * Creates SysV filesystem images for testing, optionally populated from a
 * directory tree via -d. The on-disk structures match Linux sysv_fs.h.
 */
#include <dirent.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define BLOCK_SIZE 512
#define SYSV4_SUPER_MAGIC 0xfd187e20
#define SYSV_NICINOD 100
#define SYSV_NICFREE 50
#define SYSV_BADBL_INO 1
#define SYSV_ROOT_INO 2
#define SYSV_NAME_LEN 14
#define SYSV_DIRECT_BLOCKS 10
#define SYSV_INODE_BLOCKS 32
#define SYSV_INODE_SIZE 64

struct sysv4_super_block {
    uint16_t s_isize;
    uint16_t s_pad0;
    uint32_t s_fsize;
    uint16_t s_nfree;
    uint16_t s_pad1;
    uint32_t s_free[SYSV_NICFREE];
    uint16_t s_ninode;
    uint16_t s_pad2;
    uint16_t s_inode[SYSV_NICINOD];
    char s_flock;
    char s_ilock;
    char s_fmod;
    char s_ronly;
    uint32_t s_time;
    int16_t s_dinfo[4];
    uint32_t s_tfree;
    uint16_t s_tinode;
    uint16_t s_pad3;
    char s_fname[6];
    char s_fpack[6];
    int32_t s_fill[12];
    uint32_t s_state;
    int32_t s_magic;
    uint32_t s_type;
};

struct sysv_inode {
    uint16_t i_mode;
    uint16_t i_nlink;
    uint16_t i_uid;
    uint16_t i_gid;
    uint32_t i_size;
    uint8_t i_data[39];
    uint8_t i_gen;
    uint32_t i_atime;
    uint32_t i_mtime;
    uint32_t i_ctime;
};

struct sysv_dirent {
    uint16_t inode;
    char name[SYSV_NAME_LEN];
};

_Static_assert(sizeof(struct sysv4_super_block) == 512, "bad SysV4 superblock size");
_Static_assert(sizeof(struct sysv_inode) == 64, "bad SysV inode size");
_Static_assert(sizeof(struct sysv_dirent) == 16, "bad SysV dirent size");

static int fs_fd;
static uint32_t fs_total_blocks;
static uint32_t fs_firstdatazone;
static uint32_t fs_ninodes;
static uint32_t fs_now;
static struct sysv_inode *fs_inodes;
static uint8_t *block_bitmap;
static uint8_t *inode_bitmap;

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.sysv: %s\n", msg);
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

static void read_block(uint32_t block, void *buf)
{
    if (lseek(fs_fd, (off_t)block * BLOCK_SIZE, SEEK_SET) < 0) {
        perror("lseek");
        exit(1);
    }
    if ((size_t)read(fs_fd, buf, BLOCK_SIZE) != BLOCK_SIZE) {
        perror("read");
        exit(1);
    }
}

static void write_block(uint32_t block, const void *buf)
{
    write_at((off_t)block * BLOCK_SIZE, buf, BLOCK_SIZE);
}

static void set_inode_block(struct sysv_inode *inode, uint32_t file_block,
                            uint32_t disk_block)
{
    if (file_block >= SYSV_DIRECT_BLOCKS)
        die("file too large for direct-only SysV test image");

    uint8_t *p = &inode->i_data[file_block * 3];
    p[0] = disk_block & 0xff;
    p[1] = (disk_block >> 8) & 0xff;
    p[2] = (disk_block >> 16) & 0xff;
}

static uint32_t get_inode_block(const struct sysv_inode *inode, uint32_t file_block)
{
    const uint8_t *p = &inode->i_data[file_block * 3];
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16);
}

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
    for (uint32_t i = SYSV_ROOT_INO + 1; i <= fs_ninodes; i++) {
        if (!inode_bitmap[i]) {
            inode_bitmap[i] = 1;
            return i;
        }
    }
    die("no free inodes");
    return 0;
}

static void init_dir_block(uint32_t block, uint32_t self_ino, uint32_t parent_ino)
{
    char buf[BLOCK_SIZE];
    memset(buf, 0, sizeof(buf));

    struct sysv_dirent *de = (struct sysv_dirent *)buf;
    de[0].inode = self_ino;
    memcpy(de[0].name, ".", 1);
    de[1].inode = parent_ino;
    memcpy(de[1].name, "..", 2);

    write_block(block, buf);
}

static void add_dir_entry(uint32_t dir_ino, const char *name, uint32_t child_ino)
{
    size_t name_len = strlen(name);
    size_t disk_name_len = name_len > SYSV_NAME_LEN ? SYSV_NAME_LEN : name_len;

    struct sysv_inode *dir = &fs_inodes[dir_ino - 1];
    uint32_t entries = dir->i_size / sizeof(struct sysv_dirent);
    for (uint32_t i = 0; i < entries; i++) {
        uint32_t existing_block = get_inode_block(
            dir, (i * sizeof(struct sysv_dirent)) / BLOCK_SIZE);
        uint32_t existing_off = (i * sizeof(struct sysv_dirent)) % BLOCK_SIZE;
        char existing_buf[BLOCK_SIZE];
        read_block(existing_block, existing_buf);
        struct sysv_dirent *existing =
            (struct sysv_dirent *)(existing_buf + existing_off);
        if (existing->inode != 0 &&
            memcmp(existing->name, name, disk_name_len) == 0 &&
            (disk_name_len == SYSV_NAME_LEN ||
             existing->name[disk_name_len] == '\0')) {
            fprintf(stderr, "mkfs.sysv: duplicate 14-byte directory name: %.*s\n",
                    SYSV_NAME_LEN, name);
            exit(1);
        }
    }

    uint32_t entry = dir->i_size / sizeof(struct sysv_dirent);
    uint32_t file_block = (entry * sizeof(struct sysv_dirent)) / BLOCK_SIZE;
    uint32_t block_off = (entry * sizeof(struct sysv_dirent)) % BLOCK_SIZE;

    if (file_block >= SYSV_DIRECT_BLOCKS)
        die("directory too large for direct-only SysV test image");

    uint32_t disk_block = get_inode_block(dir, file_block);
    if (!disk_block) {
        disk_block = alloc_block();
        set_inode_block(dir, file_block, disk_block);
        char zero[BLOCK_SIZE] = {0};
        write_block(disk_block, zero);
    }

    char buf[BLOCK_SIZE];
    read_block(disk_block, buf);

    struct sysv_dirent *de = (struct sysv_dirent *)(buf + block_off);
    de->inode = child_ino;
    memset(de->name, 0, sizeof(de->name));
    memcpy(de->name, name, disk_name_len);

    write_block(disk_block, buf);
    dir->i_size += sizeof(struct sysv_dirent);
}

static void write_file_data(uint32_t ino, const char *src_path)
{
    struct stat st;
    if (stat(src_path, &st) < 0) {
        perror(src_path);
        return;
    }

    struct sysv_inode *inode = &fs_inodes[ino - 1];
    inode->i_size = st.st_size;
    if (st.st_size == 0)
        return;

    int src = open(src_path, O_RDONLY);
    if (src < 0) {
        perror(src_path);
        return;
    }

    uint32_t file_block = 0;
    for (;;) {
        char buf[BLOCK_SIZE];
        memset(buf, 0, sizeof(buf));
        ssize_t n = read(src, buf, sizeof(buf));
        if (n < 0) {
            perror(src_path);
            close(src);
            exit(1);
        }
        if (n == 0)
            break;

        uint32_t disk_block = alloc_block();
        set_inode_block(inode, file_block++, disk_block);
        write_block(disk_block, buf);
    }

    close(src);
}

static void populate_dir(uint32_t dir_ino, const char *src_path)
{
    DIR *d = opendir(src_path);
    if (!d) {
        perror(src_path);
        return;
    }

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, ent->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) {
            perror(child_path);
            continue;
        }

        if (!S_ISREG(st.st_mode) && !S_ISDIR(st.st_mode))
            continue;

        uint32_t child_ino = alloc_inode();
        struct sysv_inode *child = &fs_inodes[child_ino - 1];
        child->i_mode = st.st_mode;
        child->i_uid = st.st_uid;
        child->i_gid = st.st_gid;
        child->i_atime = fs_now;
        child->i_mtime = fs_now;
        child->i_ctime = fs_now;

        add_dir_entry(dir_ino, ent->d_name, child_ino);

        if (S_ISDIR(st.st_mode)) {
            uint32_t block = alloc_block();
            set_inode_block(child, 0, block);
            child->i_mode = S_IFDIR | (st.st_mode & 0777);
            child->i_nlink = 2;
            child->i_size = 2 * sizeof(struct sysv_dirent);
            init_dir_block(block, child_ino, dir_ino);
            fs_inodes[dir_ino - 1].i_nlink++;
            populate_dir(child_ino, child_path);
        } else {
            child->i_mode = S_IFREG | (st.st_mode & 0777);
            child->i_nlink = 1;
            write_file_data(child_ino, child_path);
        }
    }

    closedir(d);
}

static void free_list_store(uint32_t block, uint16_t count, const uint32_t *blocks)
{
    char buf[BLOCK_SIZE];
    memset(buf, 0, sizeof(buf));
    memcpy(buf, &count, sizeof(count));
    memcpy(buf + 4, blocks, (size_t)count * sizeof(uint32_t));
    write_block(block, buf);
}

static uint32_t build_free_block_list(struct sysv4_super_block *sb)
{
    uint32_t blocks[SYSV_NICFREE];
    uint16_t count = 0;
    uint32_t total_free = 0;

    for (uint32_t block = fs_firstdatazone; block < fs_total_blocks; block++) {
        if (block_bitmap[block])
            continue;

        if (count == SYSV_NICFREE || count == 0) {
            free_list_store(block, count, blocks);
            count = 0;
        }

        blocks[count++] = block;
        total_free++;
    }

    sb->s_nfree = count;
    memset(sb->s_free, 0, sizeof(sb->s_free));
    memcpy(sb->s_free, blocks, (size_t)count * sizeof(uint32_t));
    return total_free;
}

static uint32_t build_free_inode_list(struct sysv4_super_block *sb)
{
    uint32_t total_free = 0;

    sb->s_ninode = 0;
    memset(sb->s_inode, 0, sizeof(sb->s_inode));

    for (uint32_t ino = SYSV_ROOT_INO + 1; ino <= fs_ninodes; ino++) {
        if (inode_bitmap[ino])
            continue;

        total_free++;
        if (sb->s_ninode < SYSV_NICINOD)
            sb->s_inode[sb->s_ninode++] = ino;
    }

    return total_free;
}

int main(int argc, char **argv)
{
    char *populate_dir_path = NULL;

    int opt;
    while ((opt = getopt(argc, argv, "d:")) != -1) {
        if (opt == 'd') {
            populate_dir_path = optarg;
        } else {
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
    if (size_mb <= 0)
        die("size must be positive");

    fs_total_blocks = (uint32_t)((uint64_t)size_mb * 1024 * 1024 / BLOCK_SIZE);
    fs_firstdatazone = 2 + SYSV_INODE_BLOCKS;
    fs_ninodes = SYSV_INODE_BLOCKS * BLOCK_SIZE / SYSV_INODE_SIZE;
    fs_now = time(NULL);

    if (fs_total_blocks <= fs_firstdatazone + 1)
        die("filesystem too small");

    block_bitmap = calloc(fs_total_blocks, 1);
    inode_bitmap = calloc(fs_ninodes + 1, 1);
    fs_inodes = calloc(fs_ninodes, sizeof(struct sysv_inode));
    if (!block_bitmap || !inode_bitmap || !fs_inodes)
        die("cannot allocate filesystem state");

    for (uint32_t b = 0; b < fs_firstdatazone; b++)
        block_bitmap[b] = 1;

    inode_bitmap[SYSV_BADBL_INO] = 1;
    inode_bitmap[SYSV_ROOT_INO] = 1;

    fs_fd = open(filename, O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fs_fd < 0) {
        perror("open");
        return 1;
    }
    if (ftruncate(fs_fd, (off_t)size_mb * 1024 * 1024) < 0) {
        perror("ftruncate");
        return 1;
    }

    uint32_t root_block = alloc_block();
    struct sysv_inode *root = &fs_inodes[SYSV_ROOT_INO - 1];
    root->i_mode = S_IFDIR | 0755;
    root->i_nlink = 2;
    root->i_size = 2 * sizeof(struct sysv_dirent);
    root->i_atime = fs_now;
    root->i_mtime = fs_now;
    root->i_ctime = fs_now;
    set_inode_block(root, 0, root_block);
    init_dir_block(root_block, SYSV_ROOT_INO, SYSV_ROOT_INO);

    if (populate_dir_path)
        populate_dir(SYSV_ROOT_INO, populate_dir_path);

    struct sysv4_super_block sb;
    memset(&sb, 0, sizeof(sb));
    sb.s_isize = fs_firstdatazone;
    sb.s_fsize = fs_total_blocks;
    sb.s_time = fs_now;
    sb.s_magic = SYSV4_SUPER_MAGIC;
    sb.s_type = 1;
    sb.s_state = 0x7c269d38 - fs_now;
    memcpy(sb.s_fname, "sysv", 4);
    memcpy(sb.s_fpack, "test", 4);
    sb.s_tfree = build_free_block_list(&sb);
    sb.s_tinode = build_free_inode_list(&sb);

    write_at(BLOCK_SIZE, &sb, sizeof(sb));
    write_at(2 * BLOCK_SIZE, fs_inodes,
             (size_t)SYSV_INODE_BLOCKS * BLOCK_SIZE);

    close(fs_fd);
    free(fs_inodes);
    free(block_bitmap);
    free(inode_bitmap);

    printf("Created SVR4 image: %s (%dMB, %u blocks, %u inodes, magic=0x%x)\n",
           filename, size_mb, fs_total_blocks, fs_ninodes, SYSV4_SUPER_MAGIC);
    printf("First data zone: %u, free blocks: %u, free inodes: %u\n",
           fs_firstdatazone, sb.s_tfree, sb.s_tinode);
    return 0;
}

/*
 * Minimal SCO BFS filesystem creator.
 *
 * Creates flat BFS filesystem images for testing, optionally populated from a
 * directory tree via -d. BFS has no subdirectories; source tree contents are
 * flattened into the root directory.
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

#define BFS_BSIZE 512
#define BFS_MAGIC 0x1badface
#define BFS_ROOT_INO 2
#define BFS_INODES_PER_BLOCK 8
#define BFS_LAST_INO 505
#define BFS_NAMELEN 14
#define BFS_DIRENT_SIZE 16
#define BFS_VREG 1
#define BFS_VDIR 2

struct bfs_inode {
    uint16_t i_ino;
    uint16_t i_unused;
    uint32_t i_sblock;
    uint32_t i_eblock;
    uint32_t i_eoffset;
    uint32_t i_vtype;
    uint32_t i_mode;
    uint32_t i_uid;
    uint32_t i_gid;
    uint32_t i_nlink;
    uint32_t i_atime;
    uint32_t i_mtime;
    uint32_t i_ctime;
    uint32_t i_padding[4];
};

struct bfs_dirent {
    uint16_t ino;
    char name[BFS_NAMELEN];
};

struct bfs_super_block {
    uint32_t s_magic;
    uint32_t s_start;
    uint32_t s_end;
    uint32_t s_from;
    uint32_t s_to;
    int32_t s_bfrom;
    int32_t s_bto;
    char s_fsname[6];
    char s_volume[6];
    uint32_t s_padding[118];
};

_Static_assert(sizeof(struct bfs_inode) == 64, "bad BFS inode size");
_Static_assert(sizeof(struct bfs_dirent) == 16, "bad BFS dirent size");
_Static_assert(sizeof(struct bfs_super_block) == 512, "bad BFS superblock size");

static int fs_fd;
static uint32_t fs_total_blocks;
static uint32_t fs_data_start_block;
static uint32_t fs_next_data_block;
static uint32_t fs_next_inode = BFS_ROOT_INO + 1;
static uint32_t fs_now;
static struct bfs_inode *fs_inodes;

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.bfs: %s\n", msg);
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
    write_at((off_t)block * BFS_BSIZE, buf, BFS_BSIZE);
}

static uint32_t inode_offset(uint32_t ino)
{
    return (ino - BFS_ROOT_INO) * sizeof(struct bfs_inode) + BFS_BSIZE;
}

static uint32_t blocks_for_size(uint32_t size)
{
    return size == 0 ? 0 : (size + BFS_BSIZE - 1) / BFS_BSIZE;
}

static struct bfs_inode *inode_by_number(uint32_t ino)
{
    return &fs_inodes[ino - BFS_ROOT_INO];
}

static void init_inode(uint32_t ino, uint32_t vtype, uint32_t mode)
{
    struct bfs_inode *inode = inode_by_number(ino);
    memset(inode, 0, sizeof(*inode));
    inode->i_ino = ino;
    inode->i_vtype = vtype;
    inode->i_mode = mode;
    inode->i_uid = 0;
    inode->i_gid = 0;
    inode->i_nlink = 1;
    inode->i_atime = fs_now;
    inode->i_mtime = fs_now;
    inode->i_ctime = fs_now;
    inode->i_eoffset = (uint32_t)-1;
}

static uint32_t alloc_inode(void)
{
    if (fs_next_inode > BFS_LAST_INO)
        die("no free inodes");
    return fs_next_inode++;
}

static uint32_t reserve_blocks(uint32_t count)
{
    uint32_t start = fs_next_data_block;
    if (count == 0)
        return 0;
    if (start + count > fs_total_blocks)
        die("no free blocks");
    fs_next_data_block += count;
    return start;
}

static void write_file_data(uint32_t ino, const char *src_path)
{
    int src = open(src_path, O_RDONLY);
    if (src < 0) {
        perror(src_path);
        exit(1);
    }

    struct stat st;
    if (fstat(src, &st) < 0) {
        perror(src_path);
        exit(1);
    }

    uint32_t size = st.st_size;
    uint32_t block_count = blocks_for_size(size);
    struct bfs_inode *inode = inode_by_number(ino);
    inode->i_mode = S_IFREG | (st.st_mode & 0777);
    inode->i_uid = st.st_uid;
    inode->i_gid = st.st_gid;

    if (block_count == 0) {
        inode->i_sblock = 0;
        inode->i_eblock = 0;
        inode->i_eoffset = (uint32_t)-1;
        close(src);
        return;
    }

    uint32_t start = reserve_blocks(block_count);
    inode->i_sblock = start;
    inode->i_eblock = start + block_count - 1;
    inode->i_eoffset = start * BFS_BSIZE + size - 1;

    for (uint32_t block = 0; block < block_count; block++) {
        char buf[BFS_BSIZE];
        memset(buf, 0, sizeof(buf));
        ssize_t n = read(src, buf, sizeof(buf));
        if (n < 0) {
            perror(src_path);
            exit(1);
        }
        write_block(start + block, buf);
    }

    close(src);
}

static size_t disk_name_len(const char *name)
{
    size_t len = strlen(name);
    return len > BFS_NAMELEN ? BFS_NAMELEN : len;
}

static void check_name_collision(const struct bfs_dirent *entries,
                                 uint32_t entry_count, const char *name)
{
    size_t name_len = disk_name_len(name);
    for (uint32_t i = 0; i < entry_count; i++) {
        if (!entries[i].ino)
            continue;
        if (memcmp(entries[i].name, name, name_len) == 0 &&
            (name_len == BFS_NAMELEN || entries[i].name[name_len] == '\0')) {
            fprintf(stderr, "mkfs.bfs: duplicate 14-byte directory name: %.*s\n",
                    BFS_NAMELEN, name);
            exit(1);
        }
    }
}

static void add_dir_entry(struct bfs_dirent *entries, uint32_t *entry_count,
                          const char *name, uint32_t ino)
{
    if (strlen(name) > BFS_NAMELEN)
        fprintf(stderr, "mkfs.bfs: warning: name truncated to %d bytes: %s\n",
                BFS_NAMELEN, name);

    check_name_collision(entries, *entry_count, name);

    struct bfs_dirent *entry = &entries[*entry_count];
    memset(entry, 0, sizeof(*entry));
    entry->ino = ino;
    memcpy(entry->name, name, disk_name_len(name));
    (*entry_count)++;
}

static void add_file_from_path(struct bfs_dirent *entries, uint32_t *entry_count,
                               const char *src_path, const char *name)
{
    uint32_t ino = alloc_inode();
    init_inode(ino, BFS_VREG, S_IFREG | 0644);
    add_dir_entry(entries, entry_count, name, ino);
    write_file_data(ino, src_path);
}

static void populate_flat(struct bfs_dirent *entries, uint32_t *entry_count,
                          const char *src_path)
{
    DIR *dir = opendir(src_path);
    if (!dir) {
        perror(src_path);
        exit(1);
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            continue;

        char child_path[4096];
        snprintf(child_path, sizeof(child_path), "%s/%s", src_path, entry->d_name);

        struct stat st;
        if (lstat(child_path, &st) < 0) {
            perror(child_path);
            closedir(dir);
            exit(1);
        }

        if (S_ISREG(st.st_mode)) {
            add_file_from_path(entries, entry_count, child_path, entry->d_name);
        } else if (S_ISDIR(st.st_mode)) {
            populate_flat(entries, entry_count, child_path);
        }
    }

    closedir(dir);
}

static void write_root_directory(const struct bfs_dirent *entries,
                                 uint32_t entry_count)
{
    struct bfs_inode *root = inode_by_number(BFS_ROOT_INO);
    uint32_t size = entry_count * sizeof(struct bfs_dirent);
    uint32_t block_count = blocks_for_size(size);
    uint32_t start = reserve_blocks(block_count);

    root->i_sblock = start;
    root->i_eblock = start + block_count - 1;
    root->i_eoffset = start * BFS_BSIZE + size - 1;

    for (uint32_t block = 0; block < block_count; block++) {
        char buf[BFS_BSIZE];
        memset(buf, 0, sizeof(buf));
        uint32_t offset = block * BFS_BSIZE;
        uint32_t remaining = size > offset ? size - offset : 0;
        uint32_t to_copy = remaining > BFS_BSIZE ? BFS_BSIZE : remaining;
        if (to_copy)
            memcpy(buf, (const char *)entries + offset, to_copy);
        write_block(start + block, buf);
    }
}

static void write_inode_table(void)
{
    for (uint32_t ino = BFS_ROOT_INO; ino < fs_next_inode; ino++) {
        write_at(inode_offset(ino), inode_by_number(ino),
                 sizeof(struct bfs_inode));
    }
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

    fs_total_blocks = (uint32_t)((uint64_t)size_mb * 1024 * 1024 / BFS_BSIZE);
    uint32_t inode_blocks =
        (BFS_LAST_INO - BFS_ROOT_INO + 1 + BFS_INODES_PER_BLOCK - 1) /
        BFS_INODES_PER_BLOCK;
    fs_data_start_block = 1 + inode_blocks;
    fs_next_data_block = fs_data_start_block;
    fs_now = time(NULL);

    if (fs_total_blocks <= fs_data_start_block + 1)
        die("filesystem too small");

    fs_inodes = calloc(BFS_LAST_INO - BFS_ROOT_INO + 1,
                       sizeof(struct bfs_inode));
    if (!fs_inodes)
        die("cannot allocate filesystem state");

    struct bfs_dirent *entries = calloc(BFS_LAST_INO, sizeof(*entries));
    if (!entries)
        die("cannot allocate root directory");
    uint32_t entry_count = 0;

    fs_fd = open(filename, O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fs_fd < 0) {
        perror("open");
        return 1;
    }
    if (ftruncate(fs_fd, (off_t)size_mb * 1024 * 1024) < 0) {
        perror("ftruncate");
        return 1;
    }

    init_inode(BFS_ROOT_INO, BFS_VDIR, S_IFDIR | 0755);
    inode_by_number(BFS_ROOT_INO)->i_nlink = 2;
    add_dir_entry(entries, &entry_count, ".", BFS_ROOT_INO);
    add_dir_entry(entries, &entry_count, "..", BFS_ROOT_INO);

    if (populate_dir_path)
        populate_flat(entries, &entry_count, populate_dir_path);

    write_root_directory(entries, entry_count);

    struct bfs_super_block sb;
    memset(&sb, 0, sizeof(sb));
    sb.s_magic = BFS_MAGIC;
    sb.s_start = fs_data_start_block * BFS_BSIZE;
    sb.s_end = fs_total_blocks * BFS_BSIZE - 1;
    sb.s_from = (uint32_t)-1;
    sb.s_to = (uint32_t)-1;
    sb.s_bfrom = -1;
    sb.s_bto = -1;
    memcpy(sb.s_fsname, "bfs", 3);
    memcpy(sb.s_volume, "basic", 5);

    write_block(0, &sb);
    write_inode_table();

    close(fs_fd);
    free(entries);
    free(fs_inodes);

    printf("Created BFS image: %s (%dMB, %u blocks, %u entries)\n",
           filename, size_mb, fs_total_blocks, entry_count);
    return 0;
}

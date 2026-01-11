/*
 * Minimal SVR4 filesystem creator
 * Based on Linux kernel include/linux/sysv_fs.h
 * Creates empty SVR4 filesystem images for testing
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <time.h>
#include <sys/stat.h>

/* SVR4 Filesystem Constants - from Linux kernel */
#define BLOCK_SIZE 512
#define SYSV4_SUPER_MAGIC 0xfd187e20  /* On-disk magic checked by kernel */
#define SYSV_NICINOD      100
#define SYSV_NICFREE      50
#define SYSV_ROOT_INO     2

/* SystemV4 super-block - matches kernel structure exactly */
struct sysv4_super_block {
    uint16_t s_isize;           /* index of first data zone */
    uint16_t s_pad0;
    uint32_t s_fsize;           /* total number of zones */
    uint16_t s_nfree;           /* number of free blocks in s_free */
    uint16_t s_pad1;
    uint32_t s_free[SYSV_NICFREE];  /* first free block list chunk */
    uint16_t s_ninode;          /* number of free inodes in s_inode */
    uint16_t s_pad2;
    uint16_t s_inode[SYSV_NICINOD]; /* some free inodes */
    char     s_flock;
    char     s_ilock;
    char     s_fmod;
    char     s_ronly;
    uint32_t s_time;
    int16_t  s_dinfo[4];
    uint32_t s_tfree;           /* total number of free zones */
    uint16_t s_tinode;          /* total number of free inodes */
    uint16_t s_pad3;
    char     s_fname[6];
    char     s_fpack[6];
    int32_t  s_fill[12];
    uint32_t s_state;           /* 0x7c269d38 - s_time means clean */
    int32_t  s_magic;           /* SYSV4_SUPER_MAGIC */
    uint32_t s_type;            /* 1=512 byte blocks, 2=1024 byte blocks */
};

/* On-disk Inode Structure (SVR4) - 64 bytes total */
struct sysv4_inode {
    uint16_t i_mode;       /* 2 bytes */
    uint16_t i_nlink;      /* 2 bytes */
    uint16_t i_uid;        /* 2 bytes */
    uint16_t i_gid;        /* 2 bytes */
    uint32_t i_size;       /* 4 bytes */
    uint8_t  i_data[39];   /* 39 bytes: 3-byte block numbers × 13 (10 direct + 3 indirect) */
    uint8_t  i_gen;        /* 1 byte: generation number */
    uint32_t i_atime;      /* 4 bytes */
    uint32_t i_mtime;      /* 4 bytes */
    uint32_t i_ctime;      /* 4 bytes */
};

/* Directory Entry - 16 bytes */
struct sysv_dirent {
    uint16_t inode;
    char name[14];
};

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <filename> <size_in_MB>\n", argv[0]);
        return 1;
    }

    char *filename = argv[1];
    int size_mb = atoi(argv[2]);
    uint32_t total_blocks = (size_mb * 1024 * 1024) / BLOCK_SIZE;
    uint32_t inode_blocks = 32;
    uint32_t data_start = inode_blocks + 2;  /* boot + super + inodes */
    uint32_t now = time(NULL);

    int fd = open(filename, O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) { perror("open"); return 1; }

    ftruncate(fd, size_mb * 1024 * 1024);

    /* Prepare Superblock */
    struct sysv4_super_block sb;
    memset(&sb, 0, sizeof(sb));
    sb.s_isize = data_start;
    sb.s_fsize = total_blocks;
    sb.s_time = now;
    sb.s_magic = SYSV4_SUPER_MAGIC;
    sb.s_type = 1;  /* 512 byte blocks */
    sb.s_state = 0x7c269d38 - now;  /* clean state */
    sb.s_tfree = total_blocks - data_start - 1;
    sb.s_tinode = (inode_blocks * BLOCK_SIZE / sizeof(struct sysv4_inode)) - 1;
    strncpy(sb.s_fname, "sysv", 6);
    strncpy(sb.s_fpack, "test", 6);

    /* Build free block list */
    uint32_t free_blk = data_start + 1;
    sb.s_nfree = 0;
    for (int i = 0; i < SYSV_NICFREE && free_blk < total_blocks; i++) {
        sb.s_free[sb.s_nfree++] = free_blk++;
    }

    /* Build free inode list */
    sb.s_ninode = 0;
    for (int i = 3; i < SYSV_NICINOD + 3 && sb.s_ninode < SYSV_NICINOD; i++) {
        sb.s_inode[sb.s_ninode++] = i;
    }

    /* Prepare Root Inode (Inode 2) */
    struct sysv4_inode root_inode;
    memset(&root_inode, 0, sizeof(root_inode));
    root_inode.i_mode = 040755;  /* directory + rwxr-xr-x */
    root_inode.i_nlink = 2;
    root_inode.i_size = 32;      /* 2 entries * 16 bytes */
    root_inode.i_atime = now;
    root_inode.i_mtime = now;
    root_inode.i_ctime = now;
    /* First direct block stored as 24-bit little-endian in i_data[0..2] */
    root_inode.i_data[0] = data_start & 0xFF;
    root_inode.i_data[1] = (data_start >> 8) & 0xFF;
    root_inode.i_data[2] = (data_start >> 16) & 0xFF;

    /* Prepare Root Directory Data */
    char root_data[BLOCK_SIZE];
    memset(root_data, 0, BLOCK_SIZE);
    struct sysv_dirent *de = (struct sysv_dirent *)root_data;
    de[0].inode = SYSV_ROOT_INO; strncpy(de[0].name, ".", 14);
    de[1].inode = SYSV_ROOT_INO; strncpy(de[1].name, "..", 14);

    /* Write to Disk */
    /* Superblock at block 1 (bytes 512-1023) */
    lseek(fd, BLOCK_SIZE, SEEK_SET);
    write(fd, &sb, sizeof(sb));

    /* Inodes start at block 2. Root inode is inode 2. */
    /* Inode 1 is bad blocks, inode 2 is root */
    lseek(fd, 2 * BLOCK_SIZE + sizeof(struct sysv4_inode), SEEK_SET);
    write(fd, &root_inode, sizeof(root_inode));

    /* Root directory data block */
    lseek(fd, data_start * BLOCK_SIZE, SEEK_SET);
    write(fd, root_data, BLOCK_SIZE);

    close(fd);
    printf("Created SVR4 image: %s (%dMB, magic=0x%x)\n",
           filename, size_mb, SYSV4_SUPER_MAGIC);
    return 0;
}

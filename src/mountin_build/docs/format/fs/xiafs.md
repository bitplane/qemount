---
title: xiafs
created: 1993
discontinued: 1997
related:
  - format/fs/ext
  - format/fs/minix
  - format/fs/ext2
detect:
  - offset: 0x23c
    type: le32
    value: 0x012fd16d
---

# Xiafs

Xiafs was created by Q. Frank Xia in 1993 as an alternative to ext, based on
the Minix filesystem. It competed with ext2 as a successor to ext, and was
initially more stable. However, ext2 evolved considerably while xiafs changed
very little, and xiafs was removed from the Linux kernel in version 2.1.21
(January 1997).

## Characteristics

- Based on Minix filesystem with extensions
- Fixed 1024-byte block size (zones can be 1KB, 2KB, or 4KB)
- Maximum volume size: 2GB
- Maximum file size: 64MB
- Filenames up to 248 characters
- 64-byte inodes (same size as ext)
- 10 zone pointers per inode (8 direct + 1 indirect + 1 double indirect)
- Variable-length directory entries
- Root inode: 1
- Block count stored in high bytes of zone pointers 0-2

## Disk Layout

- Block 0: superblock (first 512 bytes are boot sector)
- Blocks 1+: inode bitmap (imap)
- Following: zone bitmap (zmap)
- Following: inode table
- Optional: kernel image reserve
- Remaining: data zones

## Superblock (offset 0x200 within block 0)

The superblock occupies the second half of block 0 (after the 512-byte boot
sector). Fields are 32-bit little-endian:

| Offset | Field           | Description                          |
|--------|-----------------|--------------------------------------|
| 0x200  | s_zone_size     | Zone size (always 1024 for default)  |
| 0x204  | s_nzones        | Total zones in volume                |
| 0x208  | s_ninodes       | Number of inodes                     |
| 0x20C  | s_ndatazones    | Number of data zones                 |
| 0x210  | s_imap_zones    | Inode bitmap size in zones           |
| 0x214  | s_zmap_zones    | Zone bitmap size in zones            |
| 0x218  | s_firstdatazone | First data zone number               |
| 0x21C  | s_zone_shift    | Zone size = 1024 << shift            |
| 0x220  | s_max_size      | Maximum file size                    |
| 0x224  | s_reserved0-3   | Reserved (4 fields)                  |
| 0x234  | s_firstkernzone | First kernel reserve zone            |
| 0x238  | s_kernzones     | Kernel reserve size in zones         |
| 0x23C  | s_magic         | Magic number: 0x012FD16D             |

## Inode (64 bytes)

| Offset | Size | Field    | Description                          |
|--------|------|----------|--------------------------------------|
| 0x00   | 2    | i_mode   | File mode (permissions + type)       |
| 0x02   | 2    | i_nlinks | Hard link count                      |
| 0x04   | 2    | i_uid    | Owner user ID                        |
| 0x06   | 2    | i_gid    | Owner group ID                       |
| 0x08   | 4    | i_size   | File size in bytes                   |
| 0x0C   | 4    | i_ctime  | Creation time                        |
| 0x10   | 4    | i_atime  | Access time                          |
| 0x14   | 4    | i_mtime  | Modification time                    |
| 0x18   | 40   | i_zone   | 10 zone pointers (4 bytes each)      |

The high byte of zone pointers 0-2 is repurposed to store the file's block
count (24 bits across 3 pointers).

## Directory Entry

Variable-length, similar to ext:

| Offset | Size | Field      | Description                        |
|--------|------|------------|------------------------------------|
| 0x00   | 4    | d_ino      | Inode number                       |
| 0x04   | 2    | d_rec_len  | Record length (for traversal)      |
| 0x06   | 1    | d_name_len | Filename length                    |
| 0x07   | n    | d_name     | Filename (up to 248 characters)    |

## Detection

Magic number 0x012FD16D at offset 0x23C (little-endian 32-bit). This is
field 15 of the superblock, which starts at offset 0x200 (after the boot
sector).

## Guest Support

Removed from the Linux kernel in 2.1.21 (1997). A modern port exists
(modern-xiafs) but is not in mainline. Mounting would require a very
early Linux kernel (pre-2.1.21) as a guest, or loading the out-of-tree
module.

---
title: ext
created: 1992
related:
  - format/fs/ext2
  - format/fs/minix
detect:
  - offset: 0x438
    type: le16
    value: 0x137d
---

# Extended Filesystem (ext)

The original extended filesystem was created by Remy Card in 1992 as the first
filesystem written specifically for Linux. It replaced the Minix filesystem,
which was limited to 64MB volumes and 14-character filenames. ext used the new
VFS (Virtual Filesystem Switch) layer introduced in Linux 0.96c.

ext was quickly superseded by ext2 in 1993, which replaced the linked-list
free block tracking with bitmaps and added many other improvements. The ext
driver was removed from the Linux kernel around version 1.7 (1995).

## Characteristics

- Fixed 1024-byte block size
- Maximum filesystem size: 2GB
- Maximum filename: 255 characters
- Single timestamp per inode (no separate atime/mtime/ctime)
- Linked-list free block management (not bitmaps)
- Linked-list free inode management (stored in unused inode slots)
- 9 direct + 3 indirect block pointers per inode (256 entries per indirect)
- Variable-length directory entries (like ext2)

## Structure

- Block 0: boot block (unused)
- Block 1: superblock
- Blocks 2+: inode table (16 inodes per block, 64 bytes each)
- First data zone follows inode table
- Root directory is inode 1 (not 2 as in ext2)
- Inode 2 reserved for bad blocks list

## Detection

Magic number 0x137D at offset 0x438 (same position as the ext2/3/4 magic
0xef53). The superblock layout is entirely different from the ext2 family
despite sharing the same offset for the magic field.

## Guest Support

No modern kernel includes an ext driver. The driver was removed from Linux
in the mid-1990s. Mounting would require a userspace reader or a very early
Linux kernel (pre-1.7) as a guest.

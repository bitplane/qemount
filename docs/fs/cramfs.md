---
title: CramFS
related: fs/squashfs
type: fs
created: 1999
detection: {magic, 0x28cd3d45, 0}
---

# Compressed ROM Filesystem

CramFS is a read-only filesystem created by Linus Torvalds and Daniel Quinlan
in 1999 for the Linux operating system. It's designed for embedded systems that
don't have much space, and is used for boot images and rescue disks.

It's largely been replaced by [SquashFS](fs/squashfs), but is still used where
SquashFS is overkill due to its speed and low complexity.

# Characteristics
- Read-only - no write support by design
- Zlib compression - page-by-page, allows random access without decompressing
  entire file
- 256 byte filename limit
- Max file size: 16MB (24-bit limit)
- Max filesystem size: 256MB (with linear block addressing)
- No timestamps - only stores permissions and ownership
- No hard links - but supports symlinks

# Structure
- Fixed magic number at offset 0 (0x28cd3d45)
- Superblock contains root inode
- Inodes packed tightly (12 bytes each)
- Data blocks are zlib-compressed individually

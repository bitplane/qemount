---
title: CramFS
created: 1999
related:
  - fs/squashfs
  - fs/romfs
detect:
  any:
    - type: le32
      value: 0x28cd3d45
      then:
        - offset: 4
          type: le32
          name: size
        - offset: 36
          type: le32
          name: edition
        - offset: 40
          type: le32
          name: blocks
        - offset: 44
          type: le32
          name: files
    - type: be32
      value: 0x28cd3d45
---

# Compressed ROM Filesystem

CramFS is a read-only filesystem created by Linus Torvalds and Daniel Quinlan
in 1999 for the Linux operating system. It's designed for embedded systems that
don't have much space, and is used for boot images and rescue disks.

It's largely been replaced by [SquashFS](fs/squashfs), but is still used due to
its speed and low complexity, where SquashFS would be overkill.

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

---
title: CramFS
path: fs/cramfs
related: fs/squashfs
---

# Compressed ROM Filesystem
- Created by Linus Torvalds and Daniel Quinlan for Linux in 1999
- Designed for embedded systems with limited ROM/flash storage
- Read-only, compressed filesystem for boot images and rescue disks

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

# Trivia
- Ubiquitous in embedded Linux - routers, IoT devices, initramfs
- Simpler than SquashFS (which largely replaced it)
- Very low RAM overhead - only decompresses what's accessed
- Still useful when SquashFS is overkill

# Comparison to SquashFS:
- CramFS: simpler, older, more size-limited
- SquashFS: better compression (multiple algorithms), larger limits, more
  features
- CramFS lives on in legacy systems and tiny embedded targets


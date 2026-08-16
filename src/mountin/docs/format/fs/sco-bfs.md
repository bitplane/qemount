---
title: SCO BFS
created: 1989
related:
  - format/fs/sysv
  - format/fs/minix
detect:
  - type: le32
    value: 0x1badface
---

# SCO BFS (Boot File System)

BFS is a simple filesystem used by SCO UnixWare and other SCO Unix variants
for the /stand boot partition. It was designed for quick, simple booting
rather than general-purpose use.

Note: Not to be confused with BeOS BFS (Be File System), which is an entirely
different filesystem. Linux calls this "bfs" while BeOS's filesystem is "befs".

## Characteristics

- Flat structure (root directory only)
- Contiguous file allocation
- No subdirectories
- No special files (devices, symlinks)
- Maximum volume size: 512 MB
- 64-byte inodes
- Simple, fast boot loading

## Structure

- Superblock at offset 0
- Magic 0x1BADFACE (little-endian) at offset 0
- Inode table immediately follows superblock
- Data blocks follow inodes
- All files in root directory only

## Superblock Fields

| Offset | Size | Field               |
|--------|------|---------------------|
| 0      | 4    | Magic (0x1BADFACE)  |
| 4      | 4    | Start block of data |
| 8      | 4    | End block of data   |
| 12     | 4    | inode start offset  |
| 16     | 4    | inode end offset    |
| 20     | 4    | Root inode offset   |

## Design Philosophy

BFS is intentionally minimal:
- No directory hierarchy (flat namespace)
- Files must be contiguous (no fragmentation)
- No support for special files
- Optimized for boot-time file loading

## Use Cases

- SCO UnixWare /stand partition
- Boot kernel and boot configuration files
- Stand-alone utilities
- Not for general storage

## Linux Support

Linux has supported BFS since kernel 2.3.25 (1999). Useful for accessing
UnixWare boot partitions or legacy SCO systems.

---
title: C-FFS
created: 1997
discontinued: 2000
---

# C-FFS (Co-locating Fast File System)

C-FFS is the filesystem for MIT's EXOPC exokernel research operating system.
It runs on top of XN, the exokernel's low-level stable storage multiplexer.
The exokernel philosophy pushes filesystem implementation to user-space
"library operating systems" (libOS).

## Characteristics

- UNIX-like semantics
- Library filesystem (libFS) running in user-space
- Built on XN disk multiplexer
- User-defined functions (UDFs) for format checking
- Designed for high performance (8x faster web serving than traditional)

## Structure

### Superblock

Located at block 100 (`CFFS_SUPERBLKNO = 100`):

| Offset | Size | Field |
|--------|------|-------|
| 0 | 64 | fsname |
| 64 | 64 | metadata (fsdev, rootDInodeNum, size, etc.) |
| 128 | 128 | rootDinode |
| 256 | 128 | extradirDinode |
| 384 | 128 | xntypes array + padding |

Total size: one block (typically 4096 bytes).

### Key Fields

- `fsdev`: filesystem device identifier
- `rootDInodeNum`: root directory inode number
- `size`: total filesystem size
- `numblocks`: total block count
- `numalloced`: allocated block count
- `allocMap`: allocation bitmap pointer

## Detection

No magic number. The superblock is at block 100 and starts with a
64-byte filesystem name string. Heuristic detection would need to
check for valid structure at that offset.

## MBR Partition Type

| Type | Description |
|------|-------------|
| 0x95 | MIT EXOPC native partitions |

## XN Layer

XN is the underlying disk multiplexer that:
- Provides block-level access with capability protection
- Allows multiple library filesystems to coexist
- Uses User-Defined Functions (UDFs) in pseudo-RISC assembly
- Templates describe metadata formats (inodes, indirect blocks, etc.)

## History

- 1995: Exokernel concept published
- 1997: XOK/ExOS implementation, C-FFS developed
- 2000: Last known distribution (exopc-06-22-2000.tar.gz)
- Academic research project, not production use

## Current Status

- Source code available (MIT license + some GPL)
- No Linux kernel driver
- Academic/research only
- Would require implementing XN semantics

## References

- [GitHub: monocasa/exopc](https://github.com/monocasa/exopc) - Source mirror
- [C-FFS header](https://raw.githubusercontent.com/monocasa/exopc/master/lib/libexos/fd/cffs/cffs.h) - Structure definitions
- [MIT Exokernel Archive](https://pdos.csail.mit.edu/archive/exo/)
- [SOSP'97 Paper](https://pdos.csail.mit.edu/papers/exo-sosp97/exo-sosp97.html)

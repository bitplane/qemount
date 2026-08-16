---
title: SACFS
related:
  - format/fs/paqfs
  - format/fs/flashfs
detect:
  - offset: 0
    type: be32
    value: 0x0005acf5
  - offset: 12
    type: be32
    name: block_size
---

# SACFS

SACFS is a compressed, block-based Plan 9 filesystem for standalone images on
small persistent media. `mksacfs` recursively serializes a file tree and
`sacfs` exposes the resulting image through 9P.

## Structure

The image begins with a 32-byte big-endian header:

| Offset | Size | Field |
|---:|---:|---|
| 0 | 4 | Magic, `0x0005acf5` |
| 4 | 8 | Total image length |
| 12 | 4 | Uncompressed block size |
| 16 | 16 | MD5 field |

The root directory record follows the header. Directory records contain fixed
28-byte name, user and group fields plus Plan 9 metadata and an offset table.
File and directory payloads are divided into blocks. A negative block offset
marks data encoded with SAC compression; a positive offset identifies an
uncompressed block.

## References

- [sacfs(4)](http://man.9front.org/4/sacfs)
- [mksacfs(8)](http://man.9front.org/8/mksacfs)


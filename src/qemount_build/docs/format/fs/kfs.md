---
title: KFS
created: 1990
related:
  - format/fs/fossil
  - format/fs/cwfs
  - format/pt/plan9
detect:
  - offset: 256
    type: string
    value: "kfs wren device\n"
---

# KFS (Ken's File System)

KFS is the original Plan 9 filesystem, based on the file server code written
by Ken Thompson. It was the standard Plan 9 filesystem before Fossil replaced
it as the default.

## Characteristics

- 6KB blocks (RBUFSIZE = 6*1024)
- 28-character filename limit
- Direct and indirect block addressing
- User-space daemon (like all Plan 9 file servers)
- 9P protocol interface
- No journaling
- Maximum file size ~2GB (signed 32-bit limit)

## Structure

### Block Format

Each block is 6144 bytes:
- Data area: 6138 bytes
- Tag: identifies block type and owning file/directory

### Directory Entry (Dentry)

| Field   | Size | Description             |
|---------|------|-------------------------|
| name    | 28   | Filename                |
| uid     | 2    | User ID                 |
| gid     | 2    | Group ID                |
| mode    | 2    | Protection mode         |
| qid     | 8    | Unique identifier       |
| size    | 4    | File size in bytes      |
| dblock  | 24   | 6 direct block pointers |
| iblock  | 4    | Single indirect pointer |
| diblock | 4    | Double indirect pointer |
| atime   | 4    | Access time             |
| mtime   | 4    | Modification time       |

88 directory entries fit per block.

## Detection

KFS stores the ASCII string `kfs wren device\n` (16 bytes) at byte offset
256 of the disk. This is followed by the block size as a decimal ASCII
number (e.g. `1024\n`). Source: `devwren.c`, constant `WMAGIC`.

## History

- 1990: Original Plan 9 file server by Ken Thompson
- Used throughout Plan 9's early history
- Basis for CWFS (cached WORM variant)
- 2002: Fossil becomes the new default
- Still available in Plan 9 and 9front

## Current Status

- Superseded by Fossil as default
- Still functional in Plan 9/9front
- No Linux kernel driver
- Detectable via `kfs wren device` string at offset 256

## References

- [Plan 9 File Server paper](http://doc.cat-v.org/plan_9/2nd_edition/papers/fs)
- [kfs(4) man page](https://9p.io/magic/man2html/4/kfs)

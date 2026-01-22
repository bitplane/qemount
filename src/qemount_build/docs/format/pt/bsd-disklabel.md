---
title: BSD Disklabel
created: 1982
related:
  - format/fs/ufs1
  - format/fs/ufs2
detect:
  - offset: 512
    type: le32
    value: 0x82564557
    name: magic
  - offset: 0
    type: le32
    value: 0x82564557
    name: magic_at_zero
---

# BSD Disklabel

BSD disklabel is the native partitioning scheme for BSD operating systems.
It's typically embedded within an MBR partition or at the start of a disk.

## Characteristics

- Up to 8 or 16 partitions (slices)
- Partitions labeled a-h or a-p
- Convention: 'a' = root, 'b' = swap, 'c' = whole disk
- Can be nested inside MBR partition
- Magic number 0x82564557

## Structure

```
Offset  Size  Description
0       4     Magic (0x82564557)
4       2     Drive type
6       2     Subtype
8       16    Type name
24      16    Pack identifier
40      4     Bytes per sector
44      4     Sectors per track
48      4     Tracks per cylinder
52      4     Cylinders
...
132     4     Magic2 (0x82564557)
136     2     Checksum
138     2     Number of partitions
140     4     Boot area size
144     4     Superblock size
148     ...   Partition entries
```

## Partition Entry (16 bytes)

```
Offset  Size  Description
0       4     Size in sectors
4       4     Offset in sectors
8       4     Fragment size
12      1     Filesystem type
13      1     Fragments per block
14      2     Cylinders per group
```

## Filesystem Types

| Type | Description |
|------|-------------|
| 0    | Unused      |
| 1    | Swap        |
| 7    | 4.2BSD FFS  |
| 8    | MSDOS       |
| 9    | 4.4LFS      |
| 11   | ext2        |
| 15   | Vinum       |
| 17   | RAID        |

## Variants

- **OpenBSD**: 16 partitions (a-p)
- **FreeBSD**: 8 partitions (a-h)
- **NetBSD**: 16 partitions, different magic on some ports

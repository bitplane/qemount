---
title: Amiga RDB
type: pt
created: 1985
related:
  - fs/amiga-ffs
  - fs/amiga-ofs
detect:
  - offset: 0
    type: string
    value: "RDSK"
    name: rigid_disk_block
  - offset: 512
    type: string
    value: "RDSK"
  - offset: 1024
    type: string
    value: "RDSK"
---

# Amiga RDB (Rigid Disk Block)

The Rigid Disk Block is the Amiga's native partitioning scheme,
introduced with AmigaOS 1.3. It includes extensive metadata about
the disk geometry and filesystem parameters.

## Characteristics

- Variable number of partitions
- Stored in first 16 blocks (usually)
- Big-endian format
- Self-describing filesystem parameters
- Supports boot priority per partition
- Can store filesystem drivers on disk

## Structure

**Rigid Disk Block**
```
Offset  Size  Description
0       4     ID "RDSK" (0x5244534B)
4       4     Size in longwords
8       4     Checksum
12      4     Host ID
16      4     Block size (usually 512)
20      4     Flags
24      4     Bad block list pointer
28      4     Partition list pointer
32      4     Filesystem header pointer
...
```

**Partition Block**
```
Offset  Size  Description
0       4     ID "PART" (0x50415254)
4       4     Size in longwords
8       4     Checksum
12      4     Host ID
16      4     Next partition block
20      4     Flags
...
36      4     Drive name length
40      31    Drive name (BCPL string)
128     4     Sector size
132     4     Sectors per block
136     4     Heads
140     4     Sectors per track (cylinder)
144     4     Reserved blocks (start)
148     4     Reserved blocks (end)
...
164     4     Low cylinder
168     4     High cylinder
...
```

## Block IDs

| ID | Description |
|----|-------------|
| RDSK | Rigid Disk Block |
| PART | Partition Block |
| FSHD | Filesystem Header |
| LSEG | LoadSeg Block |
| BADB | Bad Block List |

## Detection Notes

"RDSK" can appear in the first 16 blocks. Most commonly at block 0, 1, or 2.

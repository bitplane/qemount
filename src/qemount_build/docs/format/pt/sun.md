---
title: Sun VTOC
created: 1983
related:
  - format/fs/ufs1
  - format/fs/ufs2
detect:
  - offset: 508
    type: be16
    value: 0xDABE
    name: vtoc_sanity
---

# Sun VTOC (Volume Table of Contents)

Sun VTOC is the partitioning scheme used by SunOS and Solaris.
It stores partition information in the disk label at the start of the disk.

## Characteristics

- Up to 8 partitions (slices)
- Big-endian format
- Partition 2 traditionally represents whole disk
- Disk geometry information included
- VTOC magic 0xDABE at offset 508

## Structure

**Disk Label (512 bytes)**
```
Offset  Size  Description
0       128   ASCII label
128     2     Rotation speed
130     2     Physical cylinders
132     2     Alternates per cylinder
134     6     Reserved
140     2     Interleave
142     2     Data cylinders
144     2     Alternate cylinders
148     2     Heads
150     2     Sectors per track
152     8     Reserved
...
```

**VTOC (at offset 260)**
```
Offset  Size  Description
0       4     Version
4       16    Volume name
20      2     Number of partitions
22      2     Reserved
24      ...   Partition entries
...
248     4     Sanity (0x600DDEEE)
252     4     Reserved
```

**Partition Entry (12 bytes)**
```
Offset  Size  Description
0       2     Tag (partition type)
2       2     Flags
4       4     Start sector
8       4     Size in sectors
```

## Partition Tags

| Tag | Description         |
|-----|---------------------|
| 0   | Unassigned          |
| 1   | Boot                |
| 2   | Root                |
| 3   | Swap                |
| 4   | /usr                |
| 5   | Whole disk (backup) |
| 6   | Stand               |
| 7   | /var                |
| 8   | /home               |

## Detection Notes

Look for 0xDABE at offset 508. Also check for 0x600DDEEE in VTOC.

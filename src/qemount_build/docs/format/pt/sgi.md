---
title: SGI DVH
created: 1988
related:
  - format/fs/efs
  - format/fs/xfs
detect:
  - offset: 0
    type: be32
    value: 0x0BE5A941
    name: dvh_magic
---

# SGI DVH (Disk Volume Header)

SGI DVH is the partitioning scheme used by IRIX on SGI workstations.
It includes a volume header that can contain boot files and stand-alone
programs.

## Characteristics

- Up to 16 partitions
- Big-endian format
- Volume header contains bootable files
- Partition 8 = volume header, partition 10 = whole disk
- Magic number 0x0BE5A941

## Structure

**Volume Header (512 bytes)**
```
Offset  Size  Description
0       4     Magic (0x0BE5A941)
4       2     Root partition
6       2     Swap partition
8       16    Boot file name
24      4     Reserved
...
72      40    Device parameters
112     15*16 Volume directory (15 entries)
352     16*12 Partition table (16 entries)
504     4     Checksum
508     4     Padding
```

**Volume Directory Entry (16 bytes)**
```
Offset  Size  Description
0       8     File name
8       4     Block number
12      4     Size in bytes
```

**Partition Entry (12 bytes)**
```
Offset  Size  Description
0       4     Block count
4       4     First block
8       4     Type
```

## Partition Types

| Type | Description        |
|------|--------------------|
| 0    | Volume header      |
| 1    | Replicated tracks  |
| 2    | Replicated sectors |
| 3    | Raw                |
| 4    | BSD 4.2            |
| 5    | System V           |
| 6    | Entire volume      |
| 7    | EFS                |
| 8    | Logical volume     |
| 9    | Raw logical volume |
| 10   | XFS                |
| 11   | XFS log            |
| 12   | XLV volume         |
| 13   | XVM volume         |

## Volume Directory

The volume header can store small files directly, typically used for:
- sash (stand-alone shell)
- ide (IRIX debugger)
- symmon (symbol monitor)
- boot loaders

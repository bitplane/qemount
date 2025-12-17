---
title: Minix
created: 1987
related:
  - fs/minix
  - pt/mbr
detect:
  - offset: 510
    type: le16
    value: 0xAA55
    then:
      - offset: 0x1BE
        type: u8
        value: 0x81
        name: minix_partition_type
---

# Minix Partition Table

Minix uses a modified MBR partition scheme that allows subpartitions
within a Minix primary partition, similar to BSD slices.

## Characteristics

- MBR-compatible structure
- Subpartitions within Minix partition
- Up to 4 subpartitions per Minix partition
- Used by Minix 2 and 3

## Structure

Minix partitions use standard MBR format at the disk level.
Within a partition marked as type 0x81 (Minix), there's a
secondary partition table:

**Primary MBR (disk level)**
```
Standard MBR with partition type 0x81
```

**Subpartition Table (within Minix partition)**
```
Offset  Size  Description
0       446   Boot code (optional)
446     16    Subpartition entry 1
462     16    Subpartition entry 2
478     16    Subpartition entry 3
494     16    Subpartition entry 4
510     2     Signature (0x55 0xAA)
```

## Partition Types

| Type | Description |
|------|-------------|
| 0x81 | Minix (old, <32MB) |
| 0x81 | Minix / early Linux |

## Historical Note

The 0x81 partition type was originally for Minix but was also
used by early Linux before Linux adopted 0x82 (swap) and 0x83
(native). Linux's partition parsing still handles Minix subpartitions.

## Linux Support

Linux kernel detects Minix partitions (type 0x81) and parses
subpartitions automatically (CONFIG_MINIX_SUBPARTITION).

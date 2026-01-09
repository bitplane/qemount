---
title: OpenBSD Disklabel
created: 1996
related:
  - format/pt/bsd-disklabel
  - format/fs/ufs1
detect:
  - offset: 512
    type: le32
    value: 0x82564557
    name: disklabel_magic
    then:
      - offset: 516
        type: le16
        name: drive_type
---

# OpenBSD Disklabel

OpenBSD uses its own variant of BSD disklabel with 16 partitions
(a-p) instead of the traditional 8 (a-h).

## Characteristics

- 16 partitions (a through p)
- Little-endian on most platforms
- UID-based disk identification
- Automatic disk geometry detection
- Magic 0x82564557

## vs FreeBSD/NetBSD

| Feature | OpenBSD | FreeBSD | NetBSD |
|---------|---------|---------|--------|
| Partitions | 16 (a-p) | 8 (a-h) | 16 (a-p) |
| DUID | Yes | No | No |
| Endian | Little | Little | Varies |

## DUID (Disk UID)

OpenBSD 4.0+ uses DUID for disk identification:
- Random 16-byte identifier
- Survives disk moves between controllers
- Referenced in fstab as DUID.partition

## Structure

```
Offset  Size  Description
0       4     Magic (0x82564557)
4       2     Drive type
6       2     Subtype
8       ...   Disk geometry
...
132     4     Magic2 (0x82564557)
136     2     Checksum
138     2     Number of partitions (16)
140     4     Boot area size
144     4     Superblock size
148     16*16 Partition entries (16 partitions)
```

## Partition Conventions

| Letter | OpenBSD Use |
|--------|-------------|
| a | Root (/) |
| b | Swap |
| c | Whole disk (raw) |
| d-p | User partitions |

## Linux Support

Linux handles OpenBSD disklabels via generic BSD disklabel
code (CONFIG_OSF_PARTITION). The 16-partition variant is
supported.

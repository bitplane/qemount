---
title: Ultrix
created: 1984
related:
  - format/pt/bsd-disklabel
detect:
  - offset: 0
    type: le32
    value: 0x00032957
    name: ultrix_magic
---

# Ultrix Partition Table

Ultrix was DEC's Unix implementation for VAX and MIPS systems.
Its partition table format is similar to BSD disklabel but with
DEC-specific extensions.

## Characteristics

- Little-endian format
- Similar to BSD disklabel
- Up to 8 partitions
- Magic number 0x00032957
- Used on DECstation (MIPS) and VAX

## Structure

**Disk Label**
```
Offset  Size  Description
0       4     Magic (0x00032957)
4       4     Reserved
8       ...   Disk geometry
...
```

## Partition Layout

Like BSD, Ultrix uses lettered partitions (a-h):

| Partition | Typical Use            |
|-----------|------------------------|
| a         | Root filesystem        |
| b         | Swap                   |
| c         | Whole disk             |
| d         | User data              |
| e-h       | Additional filesystems |

## Platforms

- **VAX**: Original Ultrix platform
- **DECstation**: MIPS-based workstations
- **DEC Alpha**: Early OSF/1 (later Tru64)

## Linux Support

Linux kernel can detect Ultrix disk labels (CONFIG_ULTRIX_PARTITION).
Useful for recovering data from old DEC systems.

## Historical Note

Ultrix evolved from BSD 4.2 and later 4.3. When DEC moved to
Alpha, they developed OSF/1 (later Digital Unix, then Tru64)
which used different partitioning.

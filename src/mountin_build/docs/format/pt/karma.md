---
title: Rio Karma
created: 2003
priority: -10
related:
  - format/fs/omfs
detect:
  - offset: 0x1FE
    type: le16
    value: 0xAB56
---

# Rio Karma Partition Table

The Rio Karma was a portable music player released by Digital Networks
North America (ReplayTV) in 2003. It used a custom partitioning scheme
with OMFS (Optimized MPEG File System).

## Detection

Magic 0xAB56 (LE16) at offset 510 (0x1FE).

## Structure

**Disklabel (sector 0, 512 bytes)**
```
Offset  Size  Type   Description
0x00    270   -      Reserved
0x10E   16    entry  Partition 0
0x11E   16    entry  Partition 1
0x12E   208   -      Blank
0x1FE   2     LE16   Magic (0xAB56)
```

**Partition Entry (16 bytes)**
```
Offset  Size  Type   Description
0x00    4     LE32   Reserved
0x04    1     u8     Filesystem type (0x4D = valid)
0x05    3     -      Reserved
0x08    4     LE32   Start sector
0x0C    4     LE32   Size in sectors
```

## Partitions

Only 2 partitions max. Valid if fstype == 0x4D and size > 0.

| Partition | Description          |
|-----------|----------------------|
| 0         | System/firmware      |
| 1         | Music storage (OMFS) |

## Historical Note

The Rio Karma was notable for:
- Native Ogg Vorbis support (rare in 2003)
- Built-in FM tuner
- Good audio quality
- Ethernet dock option

ReplayTV/DNNA went bankrupt in 2005, but the Karma
developed a cult following in the audiophile community.

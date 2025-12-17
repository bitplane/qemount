---
title: Rio Karma
created: 2003
related:
  - fs/omfs
detect:
  - offset: 0
    type: string
    value: "Rio"
    name: rio_signature
---

# Rio Karma Partition Table

The Rio Karma was a portable music player released by Digital Networks
North America (ReplayTV) in 2003. It used a custom partitioning scheme
with OMFS (Optimized MPEG File System).

## Characteristics

- Proprietary format
- Used with OMFS filesystem
- 20GB hard drive models
- Popular for Ogg Vorbis support

## Structure

**Partition Header**
```
Offset  Size  Description
0       3     Signature "Rio"
3       1     Version
4       ...   Partition data
```

## Partitions

Typical Rio Karma layout:

| Partition | Description |
|-----------|-------------|
| 1 | System/firmware |
| 2 | Music storage (OMFS) |

## Historical Note

The Rio Karma was notable for:
- Native Ogg Vorbis support (rare in 2003)
- Built-in FM tuner
- Good audio quality
- Ethernet dock option

ReplayTV/DNNA went bankrupt in 2005, but the Karma
developed a cult following in the audiophile community.

## Linux Support

Linux kernel has Rio Karma partition detection.
Combined with OMFS filesystem support, allows full
access to Karma music libraries.

## Use Cases Today

- Data recovery from old devices
- Retro portable audio enthusiasm
- Legacy media collection access

## Related

The Rio Karma uses OMFS (Optimized MPEG File System),
also from Sonic Solutions, designed for large media files
with minimal fragmentation.

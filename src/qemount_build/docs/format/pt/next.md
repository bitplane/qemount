---
title: NeXT Disklabel
created: 1988
related:
  - pt/bsd-disklabel
  - pt/apm
detect:
  - offset: 0
    type: be32
    value: 0x4E655854
    name: next_magic
---

# NeXT Disklabel

The NeXT disklabel was used by NeXTSTEP and OPENSTEP operating systems
on NeXT computers and later on x86 systems.

## Characteristics

- Magic "NeXT" (0x4E655854) at offset 0
- Big-endian on 68k, varies on other platforms
- Up to 8 partitions
- Similar concepts to BSD disklabel

## Structure

```
Offset  Size  Description
0       4     Magic ("NeXT" = 0x4E655854)
4       4     Checksum
8       8     Disk label name
16      4     Drive type
20      4     Sectors per track
24      4     Tracks per cylinder
28      4     Cylinders
32      4     Sectors per cylinder
36      4     Disk size in sectors
...
```

## Partition Entry

```
Offset  Size  Description
0       4     Start block
4       4     Size in blocks
8       2     Block size (usually 1024)
10      2     Fragment size
12      1     Filesystem type
13      1     Automount flag
14      2     Block optimization
16      ...   Mount point string
```

## Platforms

- **NeXT 68k**: Original black hardware
- **NeXTSTEP x86**: PC port
- **OPENSTEP**: Cross-platform version

## Historical Significance

NeXTSTEP became the foundation for:
- Mac OS X (2001)
- iOS (2007)
- All modern Apple operating systems

The NeXT disklabel was replaced by APM and later GPT
when Apple adopted NeXTSTEP as Mac OS X.

## Linux Support

Linux does not have native NeXT disklabel support.
Rarely needed as NeXT systems are collector's items.

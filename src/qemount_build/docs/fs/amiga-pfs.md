---
title: Amiga PFS
created: 1993
related:
  - fs/amiga-ffs
  - fs/amiga-sfs
  - pt/amiga-rdb
detect:
  - offset: 0
    type: string
    value: "PFS\x01"
    name: pfs1
  - offset: 0
    type: string
    value: "PFS\x02"
    name: pfs2
  - offset: 0
    type: string
    value: "PFS\x03"
    name: pfs3
  - offset: 0
    type: string
    value: "muPF"
    name: mufs
---

# PFS (Professional File System)

PFS was developed by Michiel Pelt and released commercially in 1993.
It was one of the first Amiga filesystems to offer significant
improvements over FFS, particularly for large directories.

## Characteristics

- Fast directory operations
- Efficient for large directories
- Multi-user support (muFS variant)
- Maximum file size: 4 GB (PFS2), larger (PFS3)
- B-tree directory structure
- Less crash-safe than SFS

## Versions

| Version | Magic | Features |
|---------|-------|----------|
| PFS1 | "PFS\x01" | Original |
| PFS2 | "PFS\x02" | Improved |
| PFS3 | "PFS\x03" | Large disk support |
| muFS | "muPF" | Multi-user variant |

## Structure

- Root block at start
- Magic in first 4 bytes
- Bitmap blocks for allocation
- B-tree for directories
- Anode blocks for file extents

## Key Features

- **B-tree Directories**: Fast lookups
- **Anode System**: Efficient file allocation
- **muFS**: Unix-like permissions

## PFS3 (AFS)

PFS3, also known as AFS (Amiga File System - not to be confused
with Andrew File System), added:
- Support for disks > 104 GB
- Long filename support
- Improved performance

## Platform Support

- **AmigaOS 3.x+**: Commercial/shareware
- **AmigaOS 4.x**: Included
- **MorphOS**: Supported
- **AROS**: Supported
- **Linux**: No support

## Linux Considerations

Linux has no PFS driver. Access requires:
- AROS guest
- AmigaOS emulation
- Native hardware

## Historical Note

PFS was commercial software and widely pirated in the Amiga
community. PFS3/AFS became more freely available later.
The multi-user muFS variant was popular on Amiga BBSes.

---
title: Amiga PFS
created: 1993
related:
  - format/fs/amiga-ffs
  - format/fs/amiga-sfs
  - format/pt/rdb
detect:
  any:
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
      value: "muAF"
      name: muafs
    - offset: 0
      type: string
      value: "muPF"
      name: mupfs
    - offset: 0
      type: string
      value: "AFS\x01"
      name: afs
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

| Variant | Magic     | Features           |
|---------|-----------|--------------------|
| PFS1    | "PFS\x01" | Original           |
| PFS2    | "PFS\x02" | Extended format    |
| muAF    | "muAF"    | Multi-user AFS     |
| muPFS   | "muPF"    | Multi-user PFS     |
| AFS     | "AFS\x01" | AFS variant        |

`PFS\3` is the RDB partition DOS type used to select the PFS3 handler. It is
not a third raw-filesystem magic. Current PFS3 formatting writes a `PFS\1`
boot block and may use a `PFS\2` root block for extended features.

## Structure

- Two-sector boot block at the start
- Root block at sector 2
- Big-endian on-disk structures
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
- **AROS**: Supported on little- and big-endian targets
- **Linux**: No support

## Linux Considerations

Linux has no PFS driver. Access requires a compatible AmigaOS environment,
native hardware, or an AROS guest. The AROS handler uses explicit big-endian
conversion for PFS metadata and has been exercised on both i386 and m68k.

## Historical Note

PFS was commercial software and widely pirated in the Amiga
community. PFS3/AFS became more freely available later.
The multi-user muFS variant was popular on Amiga BBSes.

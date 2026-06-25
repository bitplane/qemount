---
title: ADF (Amiga Disk File)
created: unknown
system: Commodore Amiga
extensions: [".adf"]
aliases:
  - Amiga Disk File
related:
  - format/disk/dms
  - format/fs/amiga-ffs
  - format/fs/amiga-ofs
  - format/disk/raw
---

# ADF (Amiga Disk File)

The standard raw, headerless sector image of an Amiga floppy — the most common
Amiga disk format and the form that compressed images like [DMS](dms)
decompress to. It is a straight dump of the disk's 512-byte sectors; the Amiga's
unusual track encoding is reconstructed by the controller (MAME generates Amiga
MFM tracks from the sector data).

## Geometry

Headerless; identified by file size:

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Total |
|----------|--------|-------|---------|--------------|-------|
| DD (880 KB) | 80 | 2 | 11 | 512 | 901,120 |
| DD (81-track) | 81 | 2 | 11 | 512 | 912,384 |
| HD (1.76 MB) | 80 | 2 | 22 | 512 | 1,802,240 |

The sectors typically hold an [OFS or FFS](amiga-ffs) Amiga filesystem.

## References

- MAME loader: [`src/lib/formats/ami_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ami_dsk.cpp)
- [Amiga Disk File — Wikipedia](https://en.wikipedia.org/wiki/Amiga_Disk_File)

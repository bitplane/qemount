---
title: MSX disk image
created: unknown
system: MSX (1983-)
extensions: [".dsk"]
aliases: [MSX-DOS disk, MSX floppy]
related:
  - format/fs/fat12
  - format/disk/dmk
  - format/media/msx-cas
---

# MSX disk image

A raw, headerless sector dump of a floppy disk as used by MSX home computers,
the 1983 8-bit standard backed by ASCII Corporation and Microsoft. The image is
a straight image of the disk's 512-byte sectors with no container header or
metadata; the geometry is inferred from the file size. Disks were driven by a
NEC uPD765-family floppy controller and recorded in MFM (double density), and
the on-disk filesystem is FAT12 under MSX-DOS, so an MSX `.dsk` is effectively a
PC-style FAT12 floppy image with MSX-specific boot code.

## Geometry

MAME's loader recognises five layouts, all 9 sectors per track of 512 bytes,
MFM:

| Layout | Tracks | Sides | Capacity |
|--------|--------|-------|----------|
| 5.25" SSDD | 40 | 1 | 180 KB |
| 5.25" DSDD | 40 | 2 | 360 KB |
| 3.5" SSDD | 80 | 1 | 360 KB |
| 3.5" DSDD | 80 | 2 | 720 KB |
| 3.5" DSDD (81 trk) | 81 | 2 | 729 KB |

The 720 KB 3.5" double-sided layout is the de facto MSX standard. Because there
is no header, there are no magic bytes; the image is identified by its size,
geometry, the `.dsk` extension, and — within the data — a FAT12 boot sector and
BIOS Parameter Block at offset 0.

The lower-level [DMK](dmk) container is also used for MSX floppies when a
track-level (copy-protection-faithful) image is needed, and MSX software is
likewise distributed as [cassette images](../media/msx-cas).

## References

- MAME loader: [`src/lib/formats/msx_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/msx_dsk.cpp)
  (five MFM geometries, 9x512 sectors, built on the uPD765 format base)
- [MSX-DOS — Wikipedia](https://en.wikipedia.org/wiki/MSX-DOS) (FAT12 filesystem, 720 KB standard)
- [Disk and Disk drives — MSX Info Pages (Hans Otten)](https://hansotten.file-hunter.com/technical-info/disk-and-disk-drives/)

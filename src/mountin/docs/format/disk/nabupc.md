---
title: NABU PC disk image
created: unknown
system: NABU PC (1983)
extensions: [".img", ".dsk"]
aliases: [NABU floppy, NABU CP/M disk]
related:
  - format/fs/cpm
  - format/disk/nanos
  - format/disk/raw
---

# NABU PC disk image

A raw, headerless sector image of a floppy disk from the NABU PC, a Z80-based
home computer launched in Ottawa, Canada in 1983-84. The NABU was unusual: it
was sold and rented to cable-TV subscribers and normally downloaded its software
over the cable network through an adaptor, but an optional external floppy unit
let it run CP/M from disk. The image is a plain dump of the disk's 1024-byte
sectors in MFM with no container header; geometry is inferred from the file size.

## Geometry

MAME's loader recognises three layouts, all 5 sectors per track of 1024 bytes,
double density (MFM):

| Layout | Tracks | Sides | Capacity |
|--------|--------|-------|----------|
| 5.25" SSDD | 40 | 1 | 200 KB |
| 5.25" DSDD | 40 | 2 | 400 KB |
| 3.5" DSDD | 80 | 2 | 800 KB |

There are no magic bytes; the image is identified by the `.img`/`.dsk`
extension, its size and geometry, and (within the data) a CP/M directory.
Note that NABU CP/M stores its disk parameter block in the post-index gap on
track zero, so a plain sector image does not capture everything the real machine
reads from a disk.

## References

- MAME loader: [`src/lib/formats/nabupc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/nabupc_dsk.cpp)
  (three MFM geometries, 5x1024 sectors)
- [NABU PC — A 1984 Z-80 Computer You Can Buy Today — Hackaday](https://hackaday.com/2022/11/28/nabu-pc-a-1984-z-80-computer-you-can-buy-today/)
- [NABU floppy disk format — Phil Pemberton](https://www.philpem.me.uk/oldcomp/nabu/floppy_disks) (DPB stored in track-zero post-index gap; sector images do not boot directly)

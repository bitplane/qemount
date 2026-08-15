---
title: Memotech MTX disk image
created: unknown
system: Memotech MTX (1983)
extensions: [".mfloppy"]
aliases: [MTX floppy, Memotech FDX disk]
related:
  - format/fs/cpm
  - format/disk/raw
---

# Memotech MTX disk image

A raw, headerless sector image of a floppy disk from the Memotech MTX, a British
Z80-based home computer launched in 1983. Floppy storage on the MTX was an
add-on: the FDX (Floppy Disk eXpansion) and the later SDX units bolted one or
two drives plus a WD177x-family controller onto the machine, and a CP/M 2.2
licence was bundled with them. The image is a plain dump of the disk's 256-byte
sectors in MFM with no container header; geometry is inferred from the file
size.

## Geometry

MAME's loader recognises four layouts, all 16 sectors per track of 256 bytes,
MFM:

| Layout | Tracks | Sides | Capacity |
|--------|--------|-------|----------|
| 5.25"/3.5" single-sided | 40 | 1 | 320 KB |
| 5.25"/3.5" double-sided | 80 | 2 | 640 KB |

These correspond to Memotech's "Type 3" (320 KB) and "Type 7" (640 KB) disk
formats; an earlier 160 KB "Type 2" format also existed. Because the format
carries no header there are no magic bytes; it is recognised by the `.mfloppy`
extension, size and geometry, and (within the data) a CP/M directory and
filesystem.

## References

- MAME loader: [`src/lib/formats/mtx_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/mtx_dsk.cpp)
  (four MFM geometries, 16x256 sectors, built on the WD177x format base)
- [Memotech MTX — Wikipedia](https://en.wikipedia.org/wiki/Memotech_MTX) (1983 Z80 machine, optional FDX/HDX disk units running CP/M 2.2)
- [Memotech MTX 512 — Floppy Disk Options (FDX)](http://www.primrosebank.net/computers/mtx/mtxdisksFDX.htm) (Type 2/3/7 320 KB and 640 KB formats)

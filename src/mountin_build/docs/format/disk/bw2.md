---
title: Bondwell 2 disk image
created: 1985
system: Bondwell 2 (CP/M laptop)
extensions: [".dsk"]
aliases:
  - BW2 disk image
related:
  - format/disk/bw12
  - format/fs/cpm
  - format/disk/raw
---

# Bondwell 2 disk image

A raw, headerless MFM sector image for the Bondwell 2, a 1985 CP/M 2.2 laptop
built around a 4 MHz Zilog Z80 with 64 KB of RAM and a flip-up 640×200 LCD. It
was unusual among CP/M machines in using a 3.5" floppy drive rather than 5.25"
disks.

The file is decoded through MAME's NEC uPD765 floppy framework as a plain dump
of disk sectors, with no container header or filesystem metadata in the image.

## Geometry

| Tracks | Sides | Sectors | Bytes/sector | Capacity | Encoding | Media |
|--------|-------|---------|--------------|----------|----------|-------|
| 80 | 1 | 17 | 256 | ~340 KB | MFM | 3.5" SSDD |
| 80 | 1 | 18 | 256 | ~360 KB | MFM | 3.5" SSDD |

The drive is single-sided double-density; MAME picks the sector count by file
size.

## References

- MAME loader: [`src/lib/formats/bw2_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/bw2_dsk.cpp)
- [Bondwell-2 — Wikipedia](https://en.wikipedia.org/wiki/Bondwell-2)

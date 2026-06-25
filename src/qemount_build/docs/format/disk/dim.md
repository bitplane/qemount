---
title: DIM (PC-98 floppy image)
created: unknown
system: NEC PC-98 series (Japan)
extensions: [".dim"]
aliases: [DIFC]
related:
  - format/disk/dip
  - format/pt/pc98
  - format/disk/raw
---

# DIM (PC-98 floppy image)

DIM is one of the floppy disk image formats used in the NEC PC-98 emulation
community. It stores a 2HD-class PC-98 floppy as a header followed by raw
sector data, and is closely related to the DCP/DCU family, differing in its
media-byte values and in carrying an additional identifying header.

## Structure

The image begins with a small header. Byte `0x00` is a media/type byte that
selects the track geometry; this is followed by a table of "sector present"
flags (one per possible track), some padding, and an identifying string. Sector
data proper starts at offset `0x100`.

The type byte selects among the standard PC-98 floppy layouts — typically 77
tracks, double-sided, with sectors per track and sector size varying by type
(for example 8×1024, 9×512, 15×1024, 18×1024 or 26×2048), recorded as MFM with
PC-style gap values.

## Detection

The header contains the 11-character ASCII string `DIFC HEADER` beginning at
offset `0xAB`. MAME keys identification on this string at that offset, and the
PC-98 format documentation describes the same `DIFC HEADER` marker in the DIM
header layout.

## References

- MAME loader: [`src/lib/formats/dim_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dim_dsk.cpp)
- [DCU/DCP/DIM file format — pc98.org](https://www.pc98.org/project/doc/dim.html)

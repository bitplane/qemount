---
title: Kaypro disk image
created: 1982
system: Kaypro CP/M luggable (Z80)
extensions: [".kay", ".dsk"]
aliases:
  - Kaypro II disk
  - Kaypro 2X disk
  - KAY1
  - KAY2
related:
  - format/fs/cpm
  - format/disk/raw
---

# Kaypro disk image

A raw, headerless sector dump of a 5.25" floppy from the Kaypro line of
CP/M-based "luggable" portable computers, which Non-Linear Systems began selling
with the Kaypro II in 1982. The image is simply the 512-byte data field of every
sector stored in track-then-sector order, with no inter-sector information,
metadata, or header — "just like a headerless quickload," as MAME's loader puts
it. The on-disk content is a [CP/M](../fs/cpm.md) filesystem.

## Geometry

Both Kaypro variants use 512-byte sectors at 48 tpi in MFM (double density),
with ten sectors per track across 40 tracks:

| Variant | Sides | Sectors/track | Capacity |
|---------|-------|---------------|----------|
| Kaypro II / 2 (SSDD) | 1 | 10 | ~191 KB |
| Kaypro 2X / 4 / 10 (DSDD) | 2 | 10 per side (20 total) | ~382 KB |

The single-sided image numbers its sectors 0–9; the double-sided variant numbers
side two's sectors 10–19, which is how MAME's two formats (`kayproii` and
`kaypro2x`) tell the geometries apart on read.

Because the image carries no header there are no magic bytes; it is recognised by
size, geometry, and extension. These disks were traditionally distributed with a
`.dsk` extension, but that collides with the unrelated CPCEMU `.dsk` format, so
Kaypro images are conventionally renamed to `.kay` to disambiguate.

## References

- MAME loader: [`src/lib/formats/kaypro_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/kaypro_dsk.cpp)
- [Kaypro — Formatting a Floppy Disk — retrocmp.de](https://retrocmp.de/kaypro/kay-p23_fdfmt.htm)
- [cpmtools diskdefs (KAY1/KAY2 definitions)](https://github.com/lipro-cpm4l/cpmtools/blob/cpm4l/cpmtools-2.21/diskdefs)

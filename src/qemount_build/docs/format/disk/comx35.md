---
title: COMX-35 disk image
created: 1983
system: RCA COMX-35
extensions: [".img"]
aliases:
  - COMX DOS disk
related:
  - format/disk/raw
---

# COMX-35 disk image

A raw, headerless sector image for the floppy system of the COMX-35, an RCA
1802-based home computer sold from 1983 (designed in Hong Kong by Comx World
Operations). The optional floppy controller used a Western Digital WD1770 and
connected 5.25" drives; COMX DOS formatted disks with 35 tracks of 16 sectors,
128 bytes each, in FM single density.

## Geometry

The image carries no header; geometry is fixed by the variant:

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Encoding |
|----------|--------|-------|---------|--------------|----------|
| 70 KB | 35 | 1 | 16 | 128 | FM SD |
| 140 KB | 35 | 2 | 16 | 128 | FM SD |

Sectors are physically interleaved on the track. MAME's source notes (but does
not implement) a possible convention where the first file byte `0x01` marks a
single-sided image, and a third 70-track double-density variant is defined but
disabled.

## References

- MAME loader: [`src/lib/formats/comx35_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/comx35_dsk.cpp)
- [COMX-35 — Wikipedia](https://en.wikipedia.org/wiki/Comx-35)
- [COMX-35 floppy — comx35.com](http://www.comx35.com/floppy.html)

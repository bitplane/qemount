---
title: Corvus Concept disk image
created: 1982
system: Corvus Concept
extensions: [".img"]
aliases:
  - Corvus Concept floppy
related:
  - format/disk/raw
---

# Corvus Concept disk image

A raw, headerless sector image for the 5.25" floppy drive of the Corvus Concept,
a 68000-based professional workstation released by Corvus Systems in 1982. The
Concept was primarily a Winchester hard-disk machine; floppies served mainly to
transfer programs and data. MAME's loader reads and writes a standard
PC-style MFM layout: 77 tracks, double-sided, 9 sectors of 512 bytes per track.

## Geometry

The image has no header; geometry is fixed:

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Encoding |
|----------|--------|-------|---------|--------------|----------|
| ~711 KB | 77 | 2 | 9 | 512 | MFM DD |

A full image is 709,632 bytes (512 × 9 × 2 × 77). The loader matches by this
exact size.

## References

- MAME loader: [`src/lib/formats/concept_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/concept_dsk.cpp)
- [Corvus Systems — Wikipedia](https://en.wikipedia.org/wiki/Corvus_Systems)
- [Corvus Concept — IT History Society](https://www.ithistory.org/db/hardware/corvus-systems/corvus-concept)

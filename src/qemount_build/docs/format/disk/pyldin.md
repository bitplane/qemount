---
title: Pyldin-601 floppy image
created: 1988
system: Pyldin-601 / Puldin (Bulgaria)
extensions: [".dsk"]
aliases:
  - Puldin
  - pyldin_dsk
---

# Pyldin-601 floppy image

A raw, headerless sector image of a floppy from the **Pyldin-601** (Bulgarian:
Пълдин, also transliterated *Puldin*), a Bulgarian 8-bit home/education computer
that entered production in 1988. The Pyldin was built around the CM601, a
Bulgarian-made copy of the Motorola 6800 CPU, and was produced in several
variants (601-A/U/M/T); most units were exported to the Soviet Union.

This image is a straight dump of the disk's sectors with no container header or
metadata — geometry is implied by context and the `.dsk` extension.

## Geometry

Per MAME's loader, the format is a fixed-geometry MFM image:

| Property | Value |
|----------|-------|
| Tracks (cylinders) | 80 |
| Heads | 2 |
| Sectors / track | 9 |
| Bytes / sector | 512 |
| Sector numbering | starts at 1 |
| Total size | 737,280 bytes (720 KB) |

The 80/2/9/512 layout is the common 720 KB double-density geometry. MAME's
descriptor tags the drive as 5.25" high-density (`FF_525`, `DSHD`) running at
1,200 (1 µs cell / 360 rpm) and notes that its gap values are unverified.

Because the format carries no header there are no magic bytes; it is recognised
by its fixed size and geometry plus the `.dsk` extension, so there is no
Detection section.

## References

- MAME loader: [`src/lib/formats/pyldin_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/pyldin_dsk.cpp)
- [Retro Computer Puldin — olimex](https://olimex.wordpress.com/2015/01/12/retro-computer-puldin-the-only-bulgarian-8-bit-computer-developed-from-scratch/)
- [pdaxrom/pyldin601 — Pyldin 601 emulator](https://github.com/pdaxrom/pyldin601)
- [Pravetz and Puldin — pc-freak.net](https://www.pc-freak.net/blog/pravetz/)

---
title: Ensoniq 16-bit instrument disk
created: unknown
system: Ensoniq VFX-SD / SD-1 / EPS-16
extensions: [".img"]
aliases:
  - esq16
  - Ensoniq 800K disk
related:
  - format/disk/raw
---

# Ensoniq 16-bit instrument disk

A raw sector image of the 800 KB floppies used by Ensoniq's 16-bit synthesizers
and samplers from the late 1980s and early 1990s — the VFX-SD and SD-1 music
workstations and the EPS-16 sampler. Despite being music instruments, these
machines store their patches, sequences and samples on ordinary PC-style MFM
floppies, so the image is a conventional decoded sector dump.

## Geometry

| Property | Value |
|----------|-------|
| Tracks | 80 |
| Sides | 2 |
| Sectors / track | 10 |
| Bytes / sector | 512 |
| Encoding | PC MFM (double-sided) |
| Total | 819,200 bytes (800 KB) |

The 800 KB capacity corresponds to the 1,600 logical blocks (numbered 0–1599)
that the Ensoniq operating systems address. The image has no header; MAME
identifies it by matching the exact byte count rather than by any signature.

## References

- MAME loader: [`src/lib/formats/esq16_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/esq16_dsk.cpp)
- [Ensoniq Floppy Diskette Formats (Gary Giebler) — deepsonic.ch](https://www.deepsonic.ch/deep/docs_manuals/ensoniq_floppy_diskette_formats.pdf)
- [Ensoniq EPS — Wikipedia](https://en.wikipedia.org/wiki/Ensoniq_EPS)

---
title: Exidy Sorcerer floppy image
created: 1979
system: Exidy Sorcerer (Z80, S-100, CP/M)
extensions: [".dsk"]
aliases:
  - Sorcerer disk
  - Exidy Sorcerer floppy
related:
  - format/media/sorcerer-tape
---

# Exidy Sorcerer floppy image

A raw, fixed-geometry floppy image for the **Exidy Sorcerer**, the 1978
Z80-based S-100 computer. When fitted with an S-100 expansion chassis and a
floppy subsystem, the Sorcerer could boot CP/M; this image holds such a disk.

## Structure

The loader treats the file as a flat sector dump with a single geometry:

- 77 tracks, 1 head (single-sided)
- 16 sectors per track, numbered 1–16
- 270 bytes per sector
- Total image size: 332,640 bytes

A sector is addressed by the linear formula `270 × (16 × track + sector)`, so the
file is simply the sectors laid end to end. There is no container header or magic
number — identification rests on the geometry and the exact 332,640-byte size
rather than a signature. MAME notes a TODO about reading the Data Address Mark /
Deleted Data Address Mark to recover per-sector flags, which this raw layout does
not preserve.

## References

- MAME loader: [`src/lib/formats/sorc_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sorc_dsk.cpp)
- [Exidy Sorcerer — Wikipedia](https://en.wikipedia.org/wiki/Exidy_Sorcerer)
- [Exidy Sorcerer hard-sector floppy image format (VCFED forum)](https://www.vcfed.org/forum/forum/genres/cp-m-and-mp-m/72252-exidy-sorcerer-vista-hard-sector-floppy-disk-image-format-question)

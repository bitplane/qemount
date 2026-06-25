---
title: Agat 840K disk (HLE)
created: unknown
system: Agat (Soviet computer, loosely Apple II-compatible)
related:
  - format/disk/aim
  - format/disk/apple2
  - format/disk/raw
---

# Agat 840K disk (HLE)

A raw, headerless sector image of an 840 KB floppy for the Agat, a Soviet
microcomputer of the 1980s whose architecture was loosely modelled on the Apple
II. "HLE" (high-level emulation) means this is a decoded sector-level image, as
opposed to a low-level bitstream/flux capture of the same disk.

## Geometry

| Property | Value |
|----------|-------|
| Tracks | 80 |
| Sides | 2 |
| Sectors / track | 21 |
| Bytes / sector | 256 |
| Total | 860,160 bytes (~840 KB) |

The image has no header; MAME identifies it by size (860,160 bytes exactly, with
slightly larger variants accepted at lower confidence).

## References

- MAME loader: [`src/lib/formats/agat840k_hle_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/agat840k_hle_dsk.cpp)
- MAME loader: [`src/lib/formats/ds9_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ds9_dsk.cpp) — the Agat-9 840K variant (`.ds9` extension, format name `a9dsk`), same 80/2/21/256 = 860,160-byte geometry but a different on-disk track encoding produced by the Agat-9 controller / IKP9 copier
- [Agat (computer) — Wikipedia](https://en.wikipedia.org/wiki/Agat_(computer))
- [Agat-9 machine — Vas the Man minimaws](https://arcade.vastheman.com/minimaws/machine/agat9)

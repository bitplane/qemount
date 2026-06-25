---
title: ABC 800 interleaved (Luxor floppy image)
created: 1981
system: Luxor ABC 830 (Sweden)
related:
  - format/disk/abc800
  - format/disk/raw
---

# ABC 800 interleaved (Luxor floppy image)

A variant of the [ABC 800](abc800) floppy image for the Luxor ABC 830 in which
the sectors are stored in a hardware **interleaved** order rather than
sequentially, to optimise read performance. The payload is otherwise the same
raw sector data.

## Geometry

Two single-sided formats, each with a fixed interleave table:

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Encoding | Sector order |
|----------|--------|-------|---------|--------------|----------|--------------|
| 80 KB | 40 | 1 | 16 | 128 | FM | 1,2,11,12,5,6,15,16,9,10,3,4,13,14,7,8 |
| 160 KB | 40 | 1 | 16 | 256 | MFM | 1,8,15,6,13,4,11,2,9,16,7,14,5,12,3,10 |

## Detection

The image is headerless. MAME distinguishes an interleaved ABC800i image from a
plain [ABC 800](abc800) image by the sector interleave together with a directory
marker — the byte at offset `0x810` is expected to be `0x03`. (This is MAME's
heuristic, not a confirmed format signature.)

## References

- MAME loader: [`src/lib/formats/abc800i_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/abc800i_dsk.cpp)
- [ABC 800 — Wikipedia](https://en.wikipedia.org/wiki/ABC_800)

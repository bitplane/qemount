---
title: Hector minidisc image (HMD)
created: 1980s
system: Micronique Hector (French Z80 home computer)
extensions: [".hmd"]
aliases:
  - Hector minidisc
related:
  - format/disk/hector-disc2
  - format/media/hector-k7
---

# Hector minidisc image (HMD)

A raw 3.5" floppy image for the "minidisc" drive option of the Micronique Hector
family (the French Z80 home computer derived from the Interact/Victor Lambda;
see [Hector Disc2](hector-disc2) for the 5.25" sibling and the system history).

The image is a fixed-geometry sector dump built on MAME's `upd765_format` base,
i.e. a standard NEC µPD765-controller MFM layout with no container header or
magic. It is identified by the `.hmd` extension and its geometry.

## Geometry

| Property | Value |
|----------|-------|
| Form factor | 3.5" DSDD |
| Encoding | MFM (2000 ns bit cell) |
| Tracks (cylinders) | 70 |
| Heads | 2 |
| Sectors / track | 9 |
| Sector size | 512 bytes |
| Capacity | ~630 KB (645,120 bytes) |

With no header there is no signature to detect; recognition relies on the
extension, the fixed geometry/size, and context.

## References

- MAME loader: [`src/lib/formats/hector_minidisc.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hector_minidisc.cpp)
- [Hector (microcomputer) — Wikipedia](https://en.wikipedia.org/wiki/Hector_(microcomputer))
- [Hector (micro-ordinateur) — Wikipédia (FR)](https://fr.wikipedia.org/wiki/Hector_(micro-ordinateur))

---
title: Tiki 100 disk image
created: 1984
system: Tiki 100 (Tiki Data, Norway; Z80)
extensions: [".dsk"]
aliases:
  - Kontiki 100 disk image
  - tiki100
related:
  - format/disk/raw
---

# Tiki 100 disk image

A raw, headerless floppy sector image for the Tiki 100, a Norwegian desktop
computer built by Tiki Data of Oslo around a 4 MHz Zilog Z80. The machine was
unveiled in late 1983 as the *Kontiki 100*; it was renamed Tiki 100 in early
1984 after Thor Heyerdahl objected to the use of the "Kon-Tiki" name. It was
widely deployed in Norwegian schools.

The image is a flat dump of disk sectors with no container header or magic. The
MAME loader recognises the byte stream against several fixed geometries built on
a WD177x-class controller model, so an image is identified by its size, the
`.dsk` extension and context rather than by any signature.

## Geometry

| Capacity | Tracks | Sides | Sectors/track | Bytes/sector | Encoding |
|----------|--------|-------|---------------|--------------|----------|
| 90 KB | 40 | 1 | 18 | 128 | FM (single density) |
| 200 KB | 40 | 1 | 10 | 512 | MFM (double density) |
| 360/400 KB | 40 | 2 | 9–10 | 512 | MFM (double density) |
| 800 KB | 80 | 2 | 10 | 512 | MFM (quad density) |

Each density uses its own sector-interleave (skew) table rather than a linear
sector order, which the loader applies when mapping file bytes onto tracks.

## References

- MAME loader:
  [`src/lib/formats/tiki100_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/tiki100_dsk.cpp)
  ("TIKI 100 disk image"; FM/MFM geometries from 90 KB to 800 KB, 256/512-byte
  sectors with per-density interleave).
- [Tiki 100 — Wikipedia](https://en.wikipedia.org/wiki/Tiki_100)
  (Tiki Data, Oslo; Z80 at 4 MHz; originally "Kontiki 100"; used in Norwegian
  schools).
- [Tiki 100 — Remi's Classic Computers](https://rclassiccomputers.com/2017/08/08/tiki-100/)

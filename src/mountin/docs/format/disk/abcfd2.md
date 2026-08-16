---
title: ABC FD2 (Scandia Metric floppy image)
created: 1978
system: Scandia Metric ABC FD2 (Luxor ABC 80, Sweden)
related:
  - format/disk/abc800
  - format/disk/raw
---

# ABC FD2 (Scandia Metric floppy image)

A raw, headerless sector image for the Scandia Metric ABC FD2, the first floppy
disk unit for the Luxor ABC 80 (Sweden, late 1970s). Scandia Metric AB marketed
the ABC 80 — designed by DIAB, manufactured by Luxor — and the FD2 housed two
5.25" single-density drives of 80 KB each.

## Geometry

Fixed geometry, FM encoding:

| Property | Value |
|----------|-------|
| Tracks | 40 |
| Sides | 1 |
| Sectors / track | 16 |
| Bytes / sector | 128 |
| Total | 81,920 bytes (80 KB) |

The image is a direct representation of the disk layout with no file-level
header or magic bytes.

## References

- MAME loader: [`src/lib/formats/abcfd2_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/abcfd2_dsk.cpp)
- [Scandia Metric — Wikipedia (sv)](https://sv.wikipedia.org/wiki/Scandia_Metric)
- [FD2/FD2U manual — abc80.net](https://www.abc80.net/archive/luxor/ABC80/Bruksanvisning-FD2-och-FD2U-Flexskivenhet.pdf)

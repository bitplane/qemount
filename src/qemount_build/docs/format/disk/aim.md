---
title: AIM (Agat disk image)
created: unknown
system: Agat (Soviet computer, loosely Apple II-compatible)
extensions: [".aim"]
related:
  - format/disk/agat840k
  - format/disk/raw
---

# AIM (Agat disk image)

A track-level disk image for the Agat Soviet microcomputer. Unlike the decoded
[Agat 840K](agat840k) sector image, AIM stores raw MFM-encoded track data, which
the loader decodes — finding index marks and sector headers — to reconstruct the
disk's sectors.

## Geometry

| Property | Value |
|----------|-------|
| Tracks | 80 |
| Sides | 2 |
| Bytes / track | 6,464 (MFM track data) |
| Total | 2,068,480 bytes |

The image has no header and is identified by its exact size.

## References

- MAME loader: [`src/lib/formats/aim_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/aim_dsk.cpp)
- [Agat (computer) — Wikipedia](https://en.wikipedia.org/wiki/Agat_(computer))

---
title: Applix 1616 floppy image
created: unknown
system: Applix 1616 (Australia)
extensions: [".raw"]
aliases:
  - Applix 1616 disk
related:
  - format/disk/raw
---

# Applix 1616 floppy image

A raw, headerless sector image for the floppy drives of the Applix 1616, a
Motorola 68000-based kit computer designed and sold by Applix Pty Ltd in Sydney,
Australia, from the mid-1980s. The machine used a Western Digital WD1772 floppy
controller and could format 3.5" (and 5.25") disks up to 800 KB.

The format carries no magic or wrapper metadata: it is a flat dump of MFM sector
data, decoded by MAME through its `wd177x_format` base class.

## Geometry

| Capacity | Tracks | Sides | Sectors/track | Bytes/sector | Encoding |
|----------|--------|-------|---------------|--------------|----------|
| 800 KB | 80 | 2 | 5 | 1024 | MFM (3.5" DSDD) |

## References

- MAME loader: [`src/lib/formats/applix_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/applix_dsk.cpp)
- [Applix 1616 — Wikipedia](https://en.wikipedia.org/wiki/Applix_1616)
- [Applix 1616 — Suzy's Blog](http://www.suzyj.net/2017/12/applix-1616.html)

---
title: NANOS disk image
created: unknown
system: NANOS (East German Z80 CP/M, mid-1980s)
extensions: [".img"]
aliases: [NANOS floppy]
related:
  - format/fs/cpm
  - format/disk/nabupc
  - format/disk/raw
---

# NANOS disk image

A raw, headerless sector image of a floppy disk from NANOS, a Z80-based modular
CP/M computer system developed in East Germany (the DDR) at the
Ingenieurhochschule für Seefahrt Warnemünde/Wustrow in the mid-1980s, using
U880 processors (the East German Zilog Z80 clone). The image is a plain dump of
the disk's 1024-byte sectors in MFM with no container header.

## Geometry

MAME's loader uses a single fixed layout, MFM:

| Property | Value |
|----------|-------|
| Tracks | 80 |
| Sides | 2 |
| Sectors / track | 5 |
| Bytes / sector | 1024 |
| Capacity | 800 KB |

This is the same 5x1024 double-sided 80-track geometry as the 800 KB
[NABU PC](nabupc) disk. There are no magic bytes; the image is identified by the
`.img` extension, its size and geometry, and (within the data) a CP/M directory.
The MAME source notes the gap sizes are unverified, so the track-level
parameters should be treated with some caution.

## References

- MAME loader: [`src/lib/formats/nanos_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/nanos_dsk.cpp)
  (single geometry, 80/2/5/1024 MFM; source flags unverified gap sizes)
- [An East German, home-built Z80 computer from the mid 1980s, running CP/M — Retro Computing Forum](https://retrocomputingforum.com/t/an-east-german-home-built-z80-computer-from-the-mid-1980s-running-cp-m/214)
- [NANOS Baugruppensystem (1989) — Ingenieurhochschule für Seefahrt Warnemünde/Wustrow, Internet Archive](https://archive.org/details/ih-fur-seefahrt-warnemunde-nanos-baugruppensystem-ausgabe-stand-01.01.1989)
- [U880 — Wikipedia](https://en.wikipedia.org/wiki/U880) (East German Z80 clone)

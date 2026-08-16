---
title: Hector Disc2 floppy image (HE2/HE7/HE8)
created: 1980s
system: Micronique Hector / Victor (French Z80 home computer)
extensions: [".he2", ".he7", ".he8"]
aliases:
  - Hector disc2
  - Hector Disk II image
related:
  - format/disk/hector-minidisc
  - format/media/hector-k7
---

# Hector Disc2 floppy image (HE2/HE7/HE8)

Raw, headerless sector dumps of the floppies used by the "Disk II" drive of the
Micronique Hector, a Z80-based home computer sold in France in the first half of
the 1980s. The Hector descends from the US Interact / Lambda Systems machine;
after Lambda's 1981 bankruptcy, Micronique acquired the design, sold it as the
Victor Lambda, and renamed the line "Hector" in 1983 to avoid confusion with
Victor Technologies. The Disk II was a dual external 5.25" drive with its own
processor.

These images are straight, fixed-geometry sector captures (MAME notes they can
be produced from real media with a tool such as AnaDisk). There is no container
header or magic; the three extensions distinguish three disk geometries, all
512-byte MFM sectors built on MAME's generic `basicdsk` handler.

## Geometry

| Ext | Heads | Tracks | Sectors/track | Sector size | Capacity |
|------|-------|--------|---------------|-------------|----------|
| `.he2` | 1 | 40 | 10 | 512 | 200 KB (204,800 bytes) |
| `.he7` | 2 | 80 | 9  | 512 | 720 KB (737,280 bytes) |
| `.he8` | 2 | 80 | 10 | 512 | 800 KB (819,200 bytes) |

Sector IDs start at 0. Because the format carries no header, there is no
signature to match; it is identified by extension, the fixed geometry/size, and
context.

For the later 3.5" minidisc drive see [Hector minidisc](hector-minidisc); for
the tape format see [Hector cassette (K7)](../media/hector-k7).

## References

- MAME loader: [`src/lib/formats/hect_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hect_dsk.cpp)
- [Hector (microcomputer) — Wikipedia](https://en.wikipedia.org/wiki/Hector_(microcomputer))
- [Hector (micro-ordinateur) — Wikipédia (FR)](https://fr.wikipedia.org/wiki/Hector_(micro-ordinateur))
- [Micronique Hector — Emu-France](https://www.emu-france.com/emulateurs/10-ordinateurs/245-micronique-hector/)

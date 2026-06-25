---
title: Acorn disk images (DFS / ADFS)
created: 1982
system: Acorn BBC Micro, Electron, Archimedes
extensions: [".ssd", ".dsd", ".adf", ".adl", ".dds", ".img"]
aliases:
  - BBC disk image
  - DFS image
  - ADFS image
related:
  - format/fs/adfs
  - format/fs/filecore
  - format/fs/cpm
  - format/disk/afs
  - format/pt/acorn/adfs
  - format/disk/raw
---

# Acorn disk images (DFS / ADFS)

A family of raw, headerless sector images for Acorn floppy disks, spanning the
BBC Micro and Electron (from 1982) through the Archimedes. They differ by
filesystem, drive geometry and (for double-sided disks) sector interleave, but
all are straight dumps of the disk's sectors. MAME's loader recognises eight
variants:

| Variant | Ext | Filesystem | Geometry (typical) | Notes |
|---------|-----|-----------|--------------------|-------|
| Acorn SSD | `.ssd`/`.bbc` | DFS | 40–80 trk, 1 side, 10×256 | single-sided |
| Acorn DSD | `.dsd` | DFS | 40–80 trk, 2 side, 10×256 | interleaved sides |
| Opus DDOS | `.dds` | DDOS | 40–80 trk, 18×256 MFM | |
| ADFS OldMap | `.adf`/`.adl` | ADFS | 16×256 | `Hugo` map id at `0x201` |
| ADFS NewMap | `.adf` | ADFS | 80 trk, 2 side, ≤10×1024 | `Hugo`/`Nick` at `0x401`/`0x801` (Archimedes) |
| Acorn DOS | `.img` | DOS/FAT | 80 trk, 2 side, 5×1024 | media id `0xFD` at offset 0 |
| Opus DD CP/M | `.ssd` | CP/M | 80 trk, 2 side | 8-byte `Slogger ` magic; 819,200 bytes |
| Cumana DFS | `.img` | DFS | 40–80 trk, 9×512 | geometry from info byte at offset 14 |

## Detection

Most variants are headerless and distinguished by size and geometry. Some carry
recognisable markers that MAME (and Acorn tooling) use: the ADFS map identifiers
`Hugo` (old map) and `Nick` (new map), the Acorn DOS media byte `0xFD`, and the
Opus DD CP/M `Slogger ` signature.

## References

- MAME loader: [`src/lib/formats/acorn_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/acorn_dsk.cpp)
- [Disc filing system (DFS) — Wikipedia](https://en.wikipedia.org/wiki/Disc_Filing_System)
- [Advanced Disc Filing System (ADFS) — Wikipedia](https://en.wikipedia.org/wiki/Advanced_Disc_Filing_System)

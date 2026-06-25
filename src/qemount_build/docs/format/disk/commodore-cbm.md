---
title: Commodore PET/CBM disk images (2040/3040/4040/8280)
created: 1979
system: Commodore PET/CBM IEEE-488 disk drives
extensions: [".d67", ".d64", ".dsk"]
aliases:
  - CBM dual drive image
  - Commodore IEEE-488 disk image
related:
  - format/disk/raw
  - format/fs/cpm
---

# Commodore PET/CBM disk images (2040/3040/4040/8280)

A family of low-level floppy images for Commodore's PET/CBM dual disk drives,
the units that attached to PET and CBM machines over the parallel IEEE-488 bus.
MAME provides a separate loader per drive because the recording schemes differ:
the early 5.25" drives use Commodore's GCR encoding, while the 8" 8280 is the
rare Commodore drive that records in MFM. These are the IEEE-488 drives, distinct
from the later serial-bus 1541 used with the C64 — though the 4040's on-disk
format is the one the 1541 inherited, so its image is the familiar `.d64`.

GCR drives use zone-bit recording: outer tracks spin past the head faster, so
they carry more sectors than the inner tracks. Each image is a sector-level dump
(no container header); the variant is identified by file size and extension.

## Variants

| Drive | Ext | DOS / encoding | Geometry | Capacity |
|-------|-----|----------------|----------|----------|
| 2040 / 3040 | `.d67` | DOS 1.x, GCR | 35 trk, 1 side, zones 21/20/18/17 = 690 blocks × 256 B | ~176 KB |
| 4040 | `.d64` | DOS 2.x, GCR | 35 trk, 1 side, zones 21/19/18/17 = 683 blocks × 256 B | ~170 KB |
| 8280 | `.dsk` | MFM | 77 trk, 2 sides, 26 × 256 B | ~1 MB (8" DSDD) |

The 2040/3040 (DOS 1) put 20 sectors on tracks 18–24, giving 690 blocks; the
4040 (DOS 2) reduced that zone to 19 sectors for 683 blocks, the layout that
became the standard 1541 `.d64`. The 8280 is one of the rarest CBM drives.

## References

- MAME loaders:
  [`src/lib/formats/c3040_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/c3040_dsk.cpp),
  [`src/lib/formats/c4040_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/c4040_dsk.cpp),
  [`src/lib/formats/c8280_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/c8280_dsk.cpp)
- [Commodore 4040 — Wikipedia](https://en.wikipedia.org/wiki/Commodore_4040)
- [Commodore 8280 — Wikipedia](https://en.wikipedia.org/wiki/Commodore_8280)
- [Commodore CBM Dual SS/SD IEEE-488 Disk Drives — zimmers.net](https://www.zimmers.net/cbmpics/deieee.html)
- [Anatomy of the 4040 Disk Drive — pagetable.com](https://www.pagetable.com/docs/anatomy-4040.html)

---
title: Assistent 128 floppy image
created: unknown
system: Assistent 128 (Schetmash, Soviet IBM PC compatible)
extensions: [".img"]
aliases:
  - ASST128 disk image
related:
  - format/disk/raw
---

# Assistent 128 floppy image

A raw, headerless sector image for the floppy drives of the Assistent 128
(ASST128), a Soviet IBM PC-compatible microcomputer built by the Schetmash
factory in Kursk. The machine is an IBM 5150-class clone with CGA-style video;
MAME emulates it from the `asst128` driver and reads its disks through a
dedicated floppy format.

## Geometry

The image is a flat dump of the disk's sectors, with no header or magic. MAME
describes it as a single-sided, quad-density 5.25" MFM layout:

| Tracks | Sides | Sectors/track | Bytes/sector | Encoding | Data rate |
|--------|-------|---------------|--------------|----------|-----------|
| 80 | 1 | 9 | 512 | MFM | 250 kbit/s |

That works out to 360 KB per disk. MAME's loader notes that the inter-sector
gap sizes are unverified, so the format is reconstructed from the drive geometry
rather than from a documented specification.

## References

- MAME loader: [`src/lib/formats/asst128_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/asst128_dsk.cpp)
- MAME driver: [`src/mame/pc/asst128.cpp`](https://github.com/mamedev/mame/blob/master/src/mame/pc/asst128.cpp)
- [Assistent 128 — MAME machine listing (Emurom)](https://www.emurom.net/us/emulation/mame-roms/detail-91563-assistent.128.html)

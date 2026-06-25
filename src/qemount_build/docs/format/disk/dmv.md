---
title: NCR DMV (Decision Mate V floppy image)
created: unknown
system: NCR Decision Mate V
extensions: [".img"]
aliases: [Decision Mate V]
related:
  - format/disk/raw
---

# NCR DMV (Decision Mate V floppy image)

A raw, headerless sector image for the floppy drives of the NCR Decision Mate V
(DMV), a CP/M and MS-DOS capable business microcomputer NCR introduced in the
early 1980s. The machine used two vertically mounted 5.25-inch double-sided,
double-density drives.

## Geometry

The image carries no header or magic; MAME reconstructs the disk using standard
uPD765 FDC sector layout and selects between two formats by file size:

| Tracks | Sides | Sectors/track | Bytes/sector | Capacity |
|--------|-------|---------------|--------------|----------|
| 40 | 2 | 8 | 512 | 320 KB |
| 40 | 2 | 9 | 512 | 360 KB |

Both are 5.25" DSDD, MFM-encoded, with the gap parameters taken from the DMV
hardware reference. The 8-sector layout matches the DMV's distinctive 320 KB
formatted capacity.

## References

- MAME loader: [`src/lib/formats/dmv_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dmv_dsk.cpp)
- [NCR Decision Mate V — old-computers.com museum](https://www.old-computers.com/museum/computer.asp?c=299)
- [NCR Decision Mate V Computer — andremiller.net](https://www.andremiller.net/content/ncr-decision-mate-v-computer-ncr-dmv/)

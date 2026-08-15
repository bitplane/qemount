---
title: DVK MX floppy image
created: unknown
system: DVK (Soviet PDP-11-compatible microcomputer)
extensions: [".dsk", ".img"]
aliases:
  - Elektronika MX
  - MX floppy
related:
  - format/disk/bk0010
  - format/disk/a5105
  - format/disk/raw
---

# DVK MX floppy image

A sector image of floppies written by the MX floppy controller used on the
Soviet DVK line of microcomputers. DVK ("Dialogue Computing Complex") machines
were desktop systems built around the Elektronika series of LSI-11 / PDP-11
compatible processors, so the MX disks belong to the wider Soviet DEC-clone
ecosystem alongside machines like the Elektronika BK.

The MX controller always transfers a whole track at a time, so the on-disk track
layout is almost entirely defined by whichever driver formatted the disk rather
than by the hardware. The only fixed element is a mandatory `0x00F3` sync word
that the controller looks for at the start of each track (preceded by a run of
zero words); after it come the track number and the sector data. MAME's loader
knows several driver-specific track layouts — an "old" arrangement used by the
stock driver and a "new" one used by a third-party driver — and formatting tools
produced still other variants.

## Geometry

| Capacity | Tracks | Sides | Sectors/track | Bytes/sector |
|----------|--------|-------|---------------|--------------|
| 112,640 bytes | 40 | 1 | 11 | 256 |
| 225,280 bytes | 40 | 2 | 11 | 256 |
| 450,560 bytes | 80 | 2 | 11 | 256 |

The recording is single-density FM at 250 kbps. The image has no file header;
it is a decoded sector dump identified by its geometry, with the `0x00F3` value
being a track-level sync word rather than a signature at the start of the file.

## References

- MAME loader: [`src/lib/formats/dvk_mx_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dvk_mx_dsk.cpp)
- [DVK — Wikipedia](https://en.wikipedia.org/wiki/DVK)
- [DVK (LSI-11 USSR) MX Disk — HxC Floppy Emulator forum](https://torlus.com/floppy/forum/viewtopic.php?t=1384)

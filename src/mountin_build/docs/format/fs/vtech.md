---
title: VTech VZ DOS filesystem
created: 1983
system: VTech Laser 200/210/310, Dick Smith VZ-200/VZ-300
extensions: [".dsk", ".dvz"]
aliases:
  - VZ-DOS
  - VZ DOS disk
  - VZ200 disk filesystem
  - Laser 200 disk filesystem
related:
  - format/disk/vtech-disk
  - format/media/vt-cas
  - format/disk/raw
---

# VTech VZ DOS filesystem

The on-disk filesystem written by VZ-DOS, the disk operating system for VTech's
Laser 200/210/310 home computers and their rebadged twins — the Dick Smith
VZ-200 and VZ-300, sold in Australia and New Zealand from 1983. The optional
plug-in disk controller is a simple port-mapped device (I/O ports 0x10–0x1F)
driving up to two single-sided 5.25-inch drives, and the controller carries no
on-board formatting logic, so the geometry and layout below are entirely defined
by VZ-DOS in software.

## Geometry

VZ-DOS formats a disk as **40 tracks, 1 side, 16 sectors per track**, recorded
in FM (single density). The DOS arranges the 16 sectors with a two-sector
interleave (0, 11, 6, 1, 12, 7, 2, 13, 8, 3, 14, 9, 4, 15, 10, 5) to cut access
time. Each sector carries **128 bytes of user data**, giving a usable capacity
of 40 × 16 × 128 = 81,920 bytes (80 KB). Community emulator disk images
(`.dsk`, `.dvz`) are correspondingly 80 KB.

MAME's raw floppy container for these disks registers a 163,840-byte image
(256 bytes per sector); the filesystem layer on top, however, works in 128-byte
logical blocks, matching the 128-byte data sectors described by the VZ-DOS
documentation. Where the figures differ, the 128-byte / 80 KB data layout is the
one confirmed by the VZ-DOS manual and the emulator community, and is the layout
the filesystem itself uses.

## Layout

There are no subdirectories. The directory lives on **track 0, sectors 0–14**,
holding up to 126 entries (8 entries per sector). Each directory entry is 16
bytes:

| Offset | Field |
|--------|-------|
| 0x0 | File-type byte — `T` (BASIC), `B` (binary), etc.; `0x00` ends the directory, `0x01` marks a deleted entry |
| 0x1 | `:` (0x3A) separator |
| 0x2–0x9 | 8-character filename, space-padded |
| 0xA | Track of first data sector |
| 0xB | Sector of first data sector |
| 0xC–0xD | Load/start address (little-endian) |
| 0xE–0xF | End address (little-endian) |

File contents are stored as a linked chain of sectors. Within each 128-byte
data sector the first 126 bytes are file data and the last two bytes hold the
track and sector number of the next sector in the chain. Free-space allocation
is tracked by a bitmap held in sector 15.

## References

- MAME filesystem loader: [`src/lib/formats/fs_vtech.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_vtech.cpp)
- [VTech Laser 200 — Wikipedia](https://en.wikipedia.org/wiki/VTech_Laser_200)
- [VZ 300 DOS Manual — Internet Archive](https://archive.org/details/VZ300-dos-manual)
- [The Dick Smith VZ-200 / VZ-300 computer — vz200.org](http://www.vz200.org/bushy/history.htm)

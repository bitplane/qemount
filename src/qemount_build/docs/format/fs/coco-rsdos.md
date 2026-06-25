---
title: RS-DOS / Disk BASIC filesystem (CoCo)
created: 1981
system: Tandy/TRS-80 Color Computer (CoCo)
extensions: [".dsk", ".raw"]
aliases:
  - RS-DOS
  - Disk BASIC filesystem
  - Color Computer Disk BASIC
  - CoCo Disk BASIC
related:
  - format/fs/coco-os9
  - format/disk/coco-rawdsk
  - format/disk/dmk
---

# RS-DOS / Disk BASIC filesystem (CoCo)

RS-DOS is the filesystem of Tandy/Radio Shack's Disk Extended Color BASIC, the
default disk environment of the 6809-based Color Computer. It is a simple flat
(no subdirectories) filesystem laid out on a single-sided 5.25" floppy of 35
tracks (the standard) or 40, each track holding eighteen 256-byte sectors. This
is the on-disk layer; the raw image it sits in is documented at
[CoCo raw disk image](../disk/coco-rawdsk.md), and the more capable OS-9
filesystem that shares the same media is at [OS-9 RBF](coco-os9.md).

## Granules

Allocation is by *granule*, a group of nine consecutive sectors (2,304 bytes).
Each non-directory track is split into two granules — sectors 1–9 and sectors
10–18 — giving 68 granules (numbered 0–67) on a 35-track disk, since the
directory track itself is not used for file data.

## Directory track (track 17) and the FAT

Track 17 holds the filesystem metadata. Sector 2 is the granule map, a 68-byte
File Allocation Table with one byte per granule:

- `0x00`–`0x43` (0–67): the file continues in the granule with this number
  (a singly-linked chain).
- `0xC0`–`0xC9`: this is the file's last granule; the low nibble gives how many
  sectors of it are used.
- `0xFF`: free granule.

Sectors 3–11 of track 17 hold the directory: eight 32-byte entries per sector,
72 entries total. Each entry stores the 8.3 filename (8-byte name + 3-byte
extension), a one-byte file type, an ASCII/binary flag, the number of the file's
first granule, and the count of bytes used in the file's last sector. A first
byte of `0xFF` marks the end of the directory; `0x00` marks a deleted entry.
(MAME's reader scans directory sectors on track 17 for these entries.)

## File types

| Value | Type |
|-------|------|
| `0x00` | BASIC program |
| `0x01` | BASIC data |
| `0x02` | machine-language program |
| `0x03` | text-editor source |

## References

- MAME loader: [`src/lib/formats/fs_coco_rsdos.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_coco_rsdos.cpp)
- [CoCo Disk BASIC disk structure (part 1) — Sub-Etha Software](https://subethasoftware.com/2023/04/25/coco-disk-basic-disk-structure-part-1/)
- [Hacking Disk — CoCopedia](https://www.cocopedia.com/wiki/index.php/Hacking_Disk)
- [Disk BASIC Unravelled (techheap mirror)](https://techheap.packetizer.com/computers/coco/unravelled_series/disk-basic-unravelled.pdf)

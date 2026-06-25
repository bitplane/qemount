---
title: DMK (David Keil disk image)
created: unknown
system: TRS-80 (also CoCo, MSX)
extensions: [".dmk"]
aliases: [David Keil disk image]
related:
  - format/media/coco-cas
  - format/disk/cgenie
  - format/disk/raw
---

# DMK (David Keil disk image)

DMK is a low-level floppy disk image format created by David Keil for his
MS-DOS-based TRS-80 emulators. Unlike the simpler JV1/JV3 sector dumps, DMK
records each track close to the way the floppy disk controller saw it —
including address marks, gaps and density — so it can faithfully represent
copy-protected and mixed-density TRS-80 disks. The same format is also used for
Tandy Color Computer (CoCo) and MSX floppies.

## Structure

The file starts with a 16-byte header:

| Offset | Size | Meaning |
|--------|------|---------|
| 0 | 1 | Write-protect flag: `0x00` (writable) or `0xFF` |
| 1 | 1 | Number of tracks |
| 2–3 | 2 | Track length in bytes (little-endian) |
| 4 | 1 | Option flags (single/double sided, single/double density, density ignore) |
| 5–15 | 11 | Reserved (zero); the last bytes also flag real vs. virtual-drive images |

Each track image begins with a 128-byte IDAM (ID Address Mark) table: up to 64
little-endian 16-bit pointers to the sector ID marks within the track. The low
14 bits give the byte offset of the IDAM inside the track; bit 15 indicates a
double-density (MFM) sector. The remainder of the track is the raw track byte
stream the controller would read, so sector contents, CRCs and inter-sector
gaps are all preserved.

## References

- MAME loader: [`src/lib/formats/dmk_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dmk_dsk.cpp)
- [Common file formats for emulated TRS-80 floppy disks — Tim Mann](https://www.tim-mann.org/trs80/dskspec.html)
- [DMK format details — openMSX documentation](https://github.com/lutris/openmsx/blob/master/doc/DMK-Format-Details.txt)

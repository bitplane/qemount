---
title: FDD (Virtual98 PC-98 floppy image)
created: unknown
system: NEC PC-98 series (Japan)
extensions: [".fdd"]
aliases:
  - Virtual98 disk image
  - VFD
  - Virtual FDD
related:
  - format/disk/dip
  - format/disk/dim
  - format/disk/d88
  - format/pt/pc98
  - format/disk/raw
---

# FDD (Virtual98 PC-98 floppy image)

FDD is the native floppy-disk image format of the Virtual98 emulator for the NEC
PC-9800 (PC-98) series. Like [D88](d88) it stores per-sector metadata rather than
a flat dump, so it can describe each sector's geometry and can compress sectors
whose content is a single repeated byte. It is one of the common PC-98 floppy
image formats alongside D88, FDI and the [DIP](dip)/[DIM](dim) family.

## Structure

The file opens with a fixed 0xC3FC-byte header. After the signature and a
write-protect/comment area, a sector map begins at offset 0xDC, with one 12-byte
entry per sector:

| Offset | Size | Field |
|--------|------|-------|
| 0x0 | 1 | Track number (0xFF marks an unformatted/unused sector) |
| 0x1 | 1 | Head number |
| 0x2 | 1 | Sector number |
| 0x3 | 1 | Sector size code (size = 128 << value) |
| 0x4 | 1 | Fill byte: if not 0xFF, the whole sector is this repeated value and is omitted from the file; if 0xFF, the sector's data is stored in full |
| 0x5–0x7 | 3 | Unknown (MAME suggests these may relate to copy protection) |
| 0x8 | 4 | Absolute file offset of the sector data, or 0xFFFFFFFF if the sector was elided and must be regenerated from the fill byte |

The format assumes up to 160 tracks and a fixed 26 sectors per track in its map,
which is the documented limitation of Virtual98's FDD format (it cannot represent
overtracked disks or tracks with more than 26 sectors). The compression scheme —
storing only a fill byte for uniform sectors — is what keeps these images smaller
than a raw dump.

## Detection

Both the MAME loader and the PC-98 imaging documentation agree that the file
begins with the ASCII magic `VFD1.0` at offset 0x00 (the on-disk string is
`VFD1.00`, a version-tagged signature of which Virtual98 itself validates only
the leading `VFD`). Byte 0x07 is reserved and zero, followed by a 128-byte
comment field that the emulator displays.

## References

- MAME source: [`src/lib/formats/fdd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fdd_dsk.cpp)
  — checks `VFD1.0` at 0x00; 0xC3FC header; 12-byte sector-map entries from 0xDC
  with the track/head/sector/size/fill/offset fields described above.
- [FDD File Format — pc98.org](https://www.pc98.org/project/doc/fdd.html) —
  independent description of the Virtual98 format: `VFD1.00` magic (first three
  bytes checked), 0xC3FC fixed header, comment and write-protect fields, and the
  26-sectors-per-track / 160-track limit.
- [pc98-disk-tools — GitHub](https://github.com/barbeque/pc98-disk-tools)

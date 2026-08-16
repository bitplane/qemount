---
title: CPC DSK (CPCEMU)
created: 1995
system: Amstrad CPC / ZX Spectrum +3
extensions: [".dsk"]
aliases:
  - CPCEMU DSK
  - Extended DSK
  - EDSK
related:
  - format/disk/raw
  - format/fs/cpm
---

# CPC DSK (CPCEMU)

The DSK image format originated with Marco Vieth's CPCEMU emulator and became the
de-facto floppy image format for the Amstrad CPC family. Because the Amstrad PCW,
the CPC+ and the ZX Spectrum +3 share the same NEC 765 / 8272-style floppy disk
controller and AMSDOS/+3DOS disk conventions, the same container is used across
all of them.

Unlike a flat sector dump, a DSK file carries explicit per-track and per-sector
metadata taken straight from the floppy controller — sector ID fields (track,
side, sector number, size code), the FDC status register values, and deleted-data
flags. This lets it preserve copy-protected and non-standard disks that a plain
geometry image cannot describe.

## Variants

| Variant | Header tag | Track sizing |
|---------|------------|--------------|
| Standard | `MV - CPCEMU Disk-File\r\nDisk-Info\r\n` | Single track size for the whole disk, stored in the disc header |
| Extended (EDSK) | `EXTENDED CPC DSK File\r\nDisk-Info\r\n` | Per-track length table; unformatted tracks have length 0 |

The extended variant was added so that disks with mixed or non-standard track
sizes (and protections) could be represented; the `EXTENDED` tag also stops
older emulators that only understand the standard layout from misreading them.

## Structure

- **Disc Information Block** (256 bytes, at offset 0): the ASCII signature, a
  creator string, the track count (offset 0x30), the side count (offset 0x31),
  the standard track size (offset 0x32, little-endian) or, for the extended
  variant, a table of per-track lengths beginning at offset 0x34.
- **Track Information Block** (one per track, each padded to 256 bytes, the first
  starting at offset 0x100): the `Track-Info\r\n` tag, the track and side number,
  sector size code, sector count, gap length and filler byte, followed by a
  sector ID list. Each sector entry holds the four ID-field bytes, both FDC
  status registers and (extended only) the actual stored data length.
- Sector payloads follow each Track Information Block.

## Detection

The first eight bytes are `MV - CPC` for a standard DSK image, or the first
sixteen bytes are `EXTENDED CPC DSK ` for the extended (EDSK) variant. Both
signatures are widely documented and are what MAME and the CPCWiki specification
test against.

## References

- MAME loader: [`src/lib/formats/dsk_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dsk_dsk.cpp)
- [Format:DSK disk image file format — CPCWiki](https://www.cpcwiki.eu/index.php/Format:DSK_disk_image_file_format)
- [DSK (CPCEMU) — Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/DSK_(CPCEMU))
- [CPCemu documentation](https://cpc-emu.org/docu_e.html)

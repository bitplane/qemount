---
title: TIB DD-001 floppy image
created: 1991
system: Commodore 64 (TIB PLC DD-001 / Drive 2001)
extensions: [".img"]
aliases: [tibdd001, "TIB Disc Drive DD-001", "Drive 2001", "TIB PLC DD-001"]
related:
  - format/disk/pc-img
  - format/disk/commodore-disk
---

# TIB DD-001 floppy image

A raw, headerless sector image of a disk from the **TIB DD-001** (also sold as
"Drive 2001"), a 3.5-inch floppy drive for the Commodore 64 made by the UK firm
TIB PLC around 1991. The drive attaches through a cartridge in the C64 expansion
port that carries the ROM and controller electronics, with the mechanism in an
external case. Unusually for a C64 peripheral it does not use CBM DOS: it drives
a PC-pinout 3.5-inch drive and writes ordinary FAT-formatted, DOS-compatible
disks, which makes it incompatible with traditional C64 drives.

> Scope note: despite superficial resemblance, this is **not** a TI-99 device.
> "TIB" here is the manufacturer TIB PLC, not Texas Instruments; multiple
> independent sources place the DD-001 firmly in the Commodore 64 world. Earlier
> notes that grouped it with TI-99 controllers were mistaken.

## Structure

A single fixed geometry, handled in MAME through the shared `upd765_format`
machinery:

- 80 tracks, 2 heads (double-sided, double-density)
- 9 sectors per track, 512 bytes per sector
- MFM encoding
- 80 × 2 × 9 × 512 = 737,280 bytes (720 KB)

There is no container header or magic number — the `.img` file is the decoded
sector payload, identified by its size and geometry. Because the medium is a
standard 720 KB FAT floppy, the same image is essentially an MS-DOS-style 3.5-inch
disk (compare `format/disk/pc-img`); the `format/disk/commodore-disk` link is by
host system rather than by on-disk format.

## References

- MAME source: `src/lib/formats/tibdd001_dsk.cpp` and `tibdd001_dsk.h`
  (BSD-3-Clause, Curt Coder) — "TIB Disc Drive DD-001 disk images", format
  `tibdd001`, extension `img`, 80/2/9/512 MFM 720 KB.
- IDE64 News, "Floppy drive TIB PLC DD-001 / Drive 2001" (news.ide64.org, 2018) —
  C64 3.5-inch drive by TIB PLC, 1991, expansion-port cartridge, 720 KB FAT/DOS
  disks, ROM versions 1.0/1.1.
- Lemon64 / cbm-hackers mailing-list threads on the TIB PLC DD-001 — corroborate
  the 2×80×9×512 = 720 KB geometry and FAT/DOS compatibility.

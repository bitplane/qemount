---
title: CBM DOS filesystem
created: 1978
system: Commodore 8-bit (PET, VIC-20, C64, C128)
extensions: [".d64", ".d71", ".d81", ".d80", ".d82"]
aliases:
  - CBMDOS
  - Commodore DOS
  - 1541 filesystem
  - CBM DOS 2A
related:
  - format/disk/commodore-disk
  - format/disk/commodore-cbm
---

# CBM DOS filesystem

CBM DOS is the on-disk filesystem used by Commodore's intelligent disk drives
(the 1541, 1571, 1581, 2040/4040, 8050/8250 and their relatives) on the
PET/VIC-20/C64/C128 family. The DOS runs inside the drive itself, so the host
computer never sees the layout directly; what is preserved in a `.d64`/`.d71`/
`.d81`/`.d80`/`.d82` sector dump is the structure described here. This page
covers the filesystem layer; the raw image containers it lives inside are
documented under [Commodore disk images](../disk/commodore-disk.md) and
[Commodore PET/CBM disk images](../disk/commodore-cbm.md).

## Layout

The disk is addressed by track and sector. Tracks are numbered from 1, and the
drives use zone-bit recording, so the number of sectors per track steps down
toward the spindle. For the canonical 1541 (35-track, single-sided) geometry:

| Tracks | Sectors/track |
|--------|---------------|
| 1–17   | 21            |
| 18–24  | 19            |
| 25–30  | 18            |
| 31–35  | 17            |

Every sector is 256 bytes. The first two bytes of a chained sector hold the
track and sector of the next link, leaving 254 usable bytes per block. MAME's
loader also accepts the unofficial 40-track extension some tools produce.

## Directory and BAM

Track 18 is reserved for the disk's metadata. Track 18, sector 0 holds the BAM
(Block Availability Map) plus the disk header: a per-track bitmap of free/used
sectors, the 16-character disk name, a two-character disk ID, and the DOS
version/format bytes. On a standard formatted disk those format bytes read
`2A` ("2A"), identifying CBM DOS format 2A (the 1541/4040 format). The
directory begins at track 18, sector 1 and chains through further sectors on
track 18.

Each directory sector holds eight 32-byte entries. An entry records the file
type byte, the track/sector of the file's first data block, the 16-character
PETSCII filename (padded with `0xA0`), and the file's block count. Files are
stored as singly-linked chains of 254-byte sectors.

## File types

The low bits of the file-type byte select the type; the high bit (`0x80`) marks
the file as closed/allocated:

| Value | Type | Meaning |
|-------|------|---------|
| `0x80` | DEL | deleted / scratched |
| `0x81` | SEQ | sequential data |
| `0x82` | PRG | program (load address in first two bytes) |
| `0x83` | USR | user / arbitrary |
| `0x84` | REL | relative (random-access records) |

## Detection

CBM DOS volumes carry no boot signature; they are recognised structurally. The
BAM/header sector at track 18, sector 0 contains the disk name, the two-byte
disk ID, and the `2A` DOS-format marker (offsets within the header sector), and
the directory chain begins at track 18, sector 1. An unpacker confirms the
filesystem by reading that header and walking the directory rather than by any
fixed magic. Note that the directory track moves on the larger drives (track 39
on the 8050/8250, track 40 on the 1581).

## References

- MAME loader: [`src/lib/formats/fs_cbmdos.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fs_cbmdos.cpp)
- [D64 (Electronic form of a physical 1541 disk) — Peter Schepers, IST Waterloo](https://ist.uwaterloo.ca/~schepers/formats/D64.TXT)
- [Commodore 1541 disk — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/Commodore_1541_disk)
- [Commodore 1541 — C64-Wiki](https://www.c64-wiki.com/wiki/Commodore_1541)

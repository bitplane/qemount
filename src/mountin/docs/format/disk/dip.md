---
title: DIP (PC-98 floppy image)
created: unknown
system: NEC PC-98 series (Japan)
extensions: [".dip"]
aliases:
  - PC98 DIP disk image
related:
  - format/disk/dim
  - format/disk/fdd
  - format/disk/d88
  - format/pt/pc98
  - format/disk/raw
---

# DIP (PC-98 floppy image)

DIP is a floppy-disk image format for the NEC PC-9800 (PC-98) series of Japanese
personal computers. It stores a single fixed-geometry 2HD floppy as a small
header followed by a flat dump of every sector in cylinder/head/sector order.
Unlike the richer PC-98 container formats such as [D88](d88), it carries no
per-sector metadata and cannot represent mixed densities or copy protection — it
is essentially a raw image with an identifying header bolted on the front.

The format does not come from a named emulator; the PC-98 imaging community
describes it as an image produced by unknown software and later read by tools
such as the FIVEC utility. MAME's loader simply notes "PC98 DIP disk images" and
flags the header structure as not fully understood.

## Structure

The file is a 256-byte (0x100) header followed by raw sector data. The fixed
geometry is:

| Property | Value |
|----------|-------|
| Cylinders (tracks) | 77 |
| Heads (sides) | 2 |
| Sectors / track | 8 |
| Bytes / sector | 1024 |
| Sector data | 77 × 2 × 8 × 1024 = 0x134000 (1,261,568) bytes |
| Total file size | 0x134100 (1,261,824) bytes including the 0x100 header |

Community documentation describes the header as an eight-byte signature at offset
0x00 — beginning `01 08 00 13 41 00 01 00`, values that mirror the image's
geometry and total size — with the remainder of the first 16 bytes zero, and a
free-text comment field filling the rest of the header up to offset 0xFF. Sector
data proper begins at 0x100 in C/H/S order. MAME does not parse this header at
all: it identifies a DIP image purely by the exact total size (0x134100) and
treats everything after the first 256 bytes as sequential sector data. Because
only one independent source documents the signature bytes (and MAME corroborates
only the size and header length, not the magic), no detection rule is asserted
here.

## References

- MAME source: [`src/lib/formats/dip_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dip_dsk.cpp)
  — 0x100 header, 77/2/8/1024 geometry, identified by the 0x134100 file size;
  the source comment notes the header structure is uninvestigated.
- [DIP File Format — pc98.org](https://www.pc98.org/project/doc/dip.html) —
  independent description giving the same 77×2×8×1024 geometry, the 0x100 header,
  the 1,261,824-byte total, and the header signature/comment layout.

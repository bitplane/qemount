---
title: VDK disk image (Dragon/CoCo)
created: 1990s
system: Dragon 32/64 and Tandy/TRS-80 Color Computer (CoCo)
extensions: [".vdk"]
aliases:
  - PC-Dragon disk image
  - Dragon VDK
related:
  - format/disk/coco-rawdsk
  - format/disk/jvc
  - format/disk/sdf
  - format/disk/os9
---

# VDK disk image (Dragon/CoCo)

VDK is a headered floppy-disk image format for the Dragon 32/64 (and the closely
related Tandy/TRS-80 Color Computer, which shares the same 6809 floppy
ecosystem). It was introduced by the PC-Dragon emulator, evolving earlier disk
imaging work by Stewart Orchard, and is widely cited as one of the two standard
Dragon image formats alongside the headerless [JVC/DSK](jvc) layout.

Like JVC, the payload is a flat dump of MFM sectors in track, then side, then
sector-number order. What VDK adds is a small descriptive header so the geometry
and provenance travel with the image instead of being inferred from the file
size. The MAME loader assumes the common Dragon DOS geometry of 18 sectors per
track, 256 bytes per sector, sector IDs starting at 1.

## Structure

The image opens with a variable-length header (12 bytes minimum), followed by the
raw sector data. The header fields, on which the MAME source and the Dragon
preservation community agree, are:

| Offset | Size | Field |
|--------|------|-------|
| 0x0 | 2 | Signature, ASCII `dk` |
| 0x2 | 2 | Header length (little-endian; total header size, allowing a trailing name/comment area) |
| 0x4 | 1 | VDK format version |
| 0x5 | 1 | Minimum compatible version |
| 0x6 | 1 | File source identifier (which tool wrote it) |
| 0x7 | 1 | File source version |
| 0x8 | 1 | Track count |
| 0x9 | 1 | Side (head) count |
| 0xA | 1 | Flags |
| 0xB | 1 | Compression flag and name length |

Because the header length is explicit, readers skip `header_length` bytes and
then read fixed-geometry sectors. The format defines a compression flag, but in
practice VDK images in circulation are uncompressed raw-sector dumps.

## Detection

Both the MAME loader and the Dragon Archive (worldofdragon.org) preservation
notes agree that a VDK file begins with the two ASCII bytes `dk` (0x64 0x6B) at
offset 0, immediately followed by the little-endian header-length word. This
two-byte signature is the format's identifying mark.

## References

- MAME source: [`src/lib/formats/vdk_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/vdk_dsk.cpp)
  — `dk` magic at offset 0, 12-byte header (version, source, track/head counts,
  flags, name length), 18 sectors/track of 256 bytes, MFM.
- [Tape/Disk Preservation — The Dragon Archive (worldofdragon.org)](https://worldofdragon.org/index.php?title=Tape%5CDisk_Preservation)
  — documents the VDK header byte-by-byte and credits PC-Dragon (evolving Stewart
  Orchard's work); notes track/side/sector data ordering.
- [pulkomandy/ddosutils](https://github.com/pulkomandy/ddosutils) — tools that
  read Dragon32 VDK disk images, an independent implementation of the header.

---
title: Oric MFM_DISK image
created: unknown
system: Oric (Oric-1 / Atmos / Telestrat) with Microdisc / Jasmin
extensions: [".dsk"]
aliases:
  - MFM_DISK
  - Oric DSK
  - Oric new-format DSK
related:
  - format/fs/oric-jasmin
  - format/media/oric-tap
  - format/disk/raw
---

# Oric MFM_DISK image

This is the common floppy-image format for the Oric-1, Oric Atmos and Oric
Telestrat home computers, whose disc drives were driven by Western Digital
WD17xx-family controllers behind interfaces such as the Microdisc and the
Jasmin. The format is usually called **MFM_DISK** after its ASCII signature, and
is the "new" Oric DSK layout used by emulators (Euphoric, Oricutron, Oricutron-
derived cores). It supersedes an earlier "old" Oric DSK that began with the tag
`ORICDISK`.

Rather than storing clean decoded sectors, MFM_DISK keeps a byte-aligned image
of each track's MFM bitstream — sync marks, address marks and sector data in
sequence — which lets it reproduce non-standard track layouts while still being
simple to parse. The same `.dsk` extension is shared with the Oric Jasmin
*filesystem* that is typically written onto these discs; see
[`fs/oric-jasmin`](../fs/oric-jasmin.md).

## Structure

The file begins with a 256-byte header:

- Offset `0x00`: 8-byte ASCII signature `MFM_DISK`.
- Offset `0x08`: number of sides (32-bit little-endian).
- Offset `0x0C`: number of tracks (32-bit little-endian).
- Offset `0x10`: geometry/ordering flag (32-bit). Value `1` lays out all tracks
  of one side contiguously, then the next side; value `2` interleaves by track
  (all sides of track 0, then all sides of track 1, and so on).

Track data starts at offset `0x100`. Each track occupies 6400 bytes (of which
roughly the first 6250 carry useful MFM data, the remainder padding to a
256-byte boundary), so a well-formed image is `256 + 6400 × sides × tracks`
bytes. Within a track, MAME's reader scans the raw stream for the standard MFM
sync patterns — `0xa1 0xa1 0xa1` introducing address/data marks and
`0xc2 0xc2 0xc2` for index marks — and reads each sector's size from the
size code in its ID field (`128 << n`).

## Detection

MAME's loader and independent Oric file-format documentation agree that the
file starts with the 8-byte ASCII signature `MFM_DISK` at offset 0, followed by
little-endian side and track counts and a 256-byte header. (The older,
pre-MFM_DISK variant instead begins with `ORICDISK`.)

## References

- MAME loader: [`src/lib/formats/oric_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/oric_dsk.cpp)
- [Oric DSK disk format — Defence Force Wiki](https://wiki.defence-force.org/doku.php?id=oric:hardware:dsk_disk_format)
- [DSK (Oric) — Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/DSK_(Oric))
- [Oric-DSK-CRC-Fixer (TomHarte) — header notes](https://github.com/TomHarte/Oric-DSK-CRC-Fixer/blob/master/main.c)

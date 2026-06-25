---
title: Commodore disk images (.d64/.d71/.d80/.d81/.d82)
created: 1982
system: Commodore 64 / 128 / PET / CBM
extensions: [".d64", ".d71", ".d80", ".d81", ".d82", ".d41"]
aliases:
  - D64 disk image
  - 1541 disk image
  - 1571 disk image
  - 1581 disk image
  - CBM disk image
related:
  - format/disk/commodore-cbm
  - format/disk/g64
  - format/media/c64-tap
  - format/media/c64-crt
  - format/disk/raw
---

# Commodore disk images (.d64/.d71/.d80/.d81/.d82)

The `.dXX` family is the set of headerless, decoded sector dumps used by
Commodore emulators and preservation tools to hold the contents of a single
floppy. Each file is just the drive's logical blocks laid end to end, in
track-then-sector order, with no container header or magic — the variant is
identified by file size and extension. The trailing digit names the drive the
image came from.

Three of the five drives hang off the C64/C128 serial bus (1541, 1571, 1581);
the other two (8050, 8250) are the larger 5.25" units that attach to PET and CBM
machines over the parallel IEEE-488 bus. They are grouped here because they share
the one `.dXX` image convention. The IEEE-488 *drive* loaders in MAME
(2040/3040/4040/8280) are documented separately under
[Commodore PET/CBM disk images](commodore-cbm.md); this page is about the named
image-file formats themselves.

Most of these drives record in Commodore's GCR (Group Code Recording) with
zone-bit recording: outer tracks pass the head faster and carry more sectors than
inner tracks, so sectors-per-track step down in zones toward the spindle. Every
sector is 256 bytes (the CBM DOS "block"), of which 254 are usable — the first
two bytes chain to the next track/sector. The 1581 is the exception: it is a
3.5" PC-style drive that records in MFM and presents its 512-byte physical
sectors to CBM DOS as pairs of 256-byte logical blocks.

## Variants

| Image | Drive | Bus | Encoding | Geometry | Blocks | Bytes |
|-------|-------|-----|----------|----------|--------|-------|
| `.d64` | 1541 | serial | GCR | 35 trk, 1 side, zones 21/19/18/17 | 683 | 174,848 (~170 KB) |
| `.d71` | 1571 | serial | GCR | 70 trk (35×2 sides), zones 21/19/18/17 per side | 1,366 | 349,696 (~340 KB) |
| `.d80` | 8050 | IEEE-488 | GCR | 77 trk, 1 side, zones 29/27/25/23 | 2,083 | 533,248 (~520 KB) |
| `.d81` | 1581 | serial | MFM | 80 trk, 2 sides, 10×512 B (40×256 B logical/track) | 3,200 | 819,200 (~800 KB) |
| `.d82` | 8250 / SFD-1001 | IEEE-488 | GCR | 154 trk (77×2 sides), zones 29/27/25/23 per side | 4,166 | 1,066,496 (~1040 KB) |

The 1541 layout — zones of 21/19/18/17 sectors over 35 tracks, 683 blocks — is
the DOS 2 format the 1541 inherited from the earlier 4040 IEEE-488 drive, which
is why a 4040 image and a `.d64` are the same thing. The 1571 (`.d71`) simply
mirrors that layout onto a second side for double the capacity, and the 8250
(`.d82`) does the same to the 8050's (`.d80`) layout. MAME's `.d64` loader also
accepts the unofficial 40-track (768 blocks, 196,608 bytes) and 42-track (802
blocks, 205,312 bytes) extensions some tools produce by formatting past the
standard 35 tracks.

## Detection

These images are raw sector dumps with no signature, so identification rests on
the file's exact byte length together with its extension, as listed above
(174,848 for `.d64`, 349,696 for `.d71`, 533,248 for `.d80`, 819,200 for `.d81`,
1,066,496 for `.d82`). The 40-/42-track `.d64` extensions and optional per-sector
error-byte tables (one byte per block appended to the image) shift these totals,
so size matching alone is not reliable across the family. The CBM DOS directory
and Block Availability Map (BAM) live at a fixed location — track 18 sector 0 for
the 1541/1571, track 39 for the 8050/8250, track 40 for the 1581 — which an
unpacker can read to confirm the format and list files.

## References

- MAME loaders:
  [`d64_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/d64_dsk.cpp),
  [`d71_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/d71_dsk.cpp),
  [`d80_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/d80_dsk.cpp),
  [`d81_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/d81_dsk.cpp),
  [`d82_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/d82_dsk.cpp)
- [VICE manual — disk image formats](https://vice-emu.sourceforge.io/vice_17.html)
- [Disk Image — C64-Wiki](https://www.c64-wiki.com/wiki/disk_image)
- [Commodore 1581 — C64-Wiki](https://www.c64-wiki.com/wiki/Commodore_1581)
- [Commodore 1541 disk — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/Commodore_1541_disk)
- Bitstream-level sibling: the [G64 GCR disk image](g64.md) preserves the raw
  GCR track data these decoded sector images discard
  ([`g64_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/g64_dsk.cpp)).
</content>
</invoke>

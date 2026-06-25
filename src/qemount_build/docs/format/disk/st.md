---
title: ST (Atari ST raw disk image)
created: 1985
system: Atari ST
extensions: [".st"]
aliases:
  - Atari ST disk image
  - ST sector dump
related:
  - format/disk/msa
  - format/disk/stx
  - format/disk/ipf
  - format/fs/gemdos
  - format/pt/atari
  - format/disk/raw
---

# ST (Atari ST raw disk image)

The `.st` file is the plain, headerless sector dump of an Atari ST floppy disk.
It is the simplest and most common Atari ST image format: every sector of the
disk is written out back-to-back in logical order (track, then head, then
sector), with no container header, no magic bytes, no compression and no
metadata. The size of the file is exactly the size of the disk it came from.

Because there is no wrapper, an `.st` image *is* a GEMDOS volume — the same
FAT12-derived layout TOS uses — and tools can mount it directly. The disk's
geometry has to be inferred from the file size together with the BIOS Parameter
Block in the boot sector; MAME accepts the usual ST geometries of 80–82 tracks,
one or two sides, and 9, 10 or 11 sectors of 512 bytes per track (so roughly
360 KB to 900 KB).

## Relationship to the other Atari ST formats

`.st` is the raw end of a family of Atari ST image formats:

- **`.st` (this format)** — raw sectors only. Cannot represent custom timing,
  non-standard sector sizes, or copy protection. Perfect for ordinary GEMDOS
  disks, useless for protected originals.
- **[`.msa`](msa.md)** (Magic Shadow Archiver) — the same logical sector data
  but with a small header and optional per-track run-length compression, so
  empty space costs almost nothing. Decompresses to the equivalent of an `.st`.
- **[`.stx`](stx.md)** (Pasti) — a preservation format that records track
  timing, weak/fuzzy bits and odd sector layouts, capturing the copy protection
  that raw `.st`/`.msa` images throw away.
- **[`.ipf`](ipf.md)** — a cross-platform flux-level preservation format that
  similarly keeps the physical track image rather than just the sectors.

The same MAME source file implements both the raw `.st` reader and the `.msa`
reader, since the two share their sector model and geometry detection.

This is a headerless, fixed-content sector image, so there is no signature to
match; identification is by extension and by the GEMDOS boot sector (whose
16-bit big-endian word checksum is `0x1234` rather than the PC `0x55AA`
marker).

## References

- MAME loader: [`src/lib/formats/st_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/st_dsk.cpp)
  — handles both the raw `.st` and the compressed `.msa` Atari ST images.
- [ST disk image — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/ST_disk_image)
- [Atari ST floppy disk image file formats — fplanque.com](https://www.fplanque.com/tech/retro/atari/atari-st-fd-image-file-formats/)
- [DiskType: Atari ST images](https://disktype.sourceforge.net/doc/ch03s03.html)

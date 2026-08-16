---
title: TRD (TR-DOS disk image)
created: 1980s
system: ZX Spectrum (Beta Disk interface / TR-DOS)
extensions: [".trd"]
aliases:
  - TR-DOS disk image
  - Beta Disk image
related:
  - format/disk/scl
  - format/disk/opd
  - format/disk/swd
  - format/disk/sdd
  - format/disk/coupe
  - format/disk/raw
---

# TRD (TR-DOS disk image)

TRD is a raw, headerless sector image of a TR-DOS floppy as used by the
Technology Research Beta Disk interface, the dominant floppy system for the
Sinclair ZX Spectrum. The file is a straight track-by-track dump of 256-byte
sectors with no container header or magic signature; the on-disk TR-DOS
filesystem itself is the only structure present.

This is the image that the compact [SCL](scl) archive format expands into: SCL
stores just the TR-DOS catalogue plus the sectors a file actually occupies,
then reconstructs a full TRD by laying those files back onto an empty TR-DOS
disk. A TRD is therefore the "unpacked" disk, while SCL is the space-saving
interchange wrapper around the same data.

## Structure

Every track holds 16 sectors of 256 bytes. Logical tracks are stored
side-interleaved in TR-DOS order: track 0/side 0, then track 0/side 1, then
track 1/side 0, and so on. MAME recognises six layouts, all 256-byte sectors:

| Capacity | Tracks | Sides | Sectors/track | Encoding |
|----------|--------|-------|---------------|----------|
| 640 KB | 80 | 2 | 16 | MFM |
| 320 KB | 80 | 1 | 16 | MFM |
| 320 KB | 40 | 2 | 16 | MFM |
| 160 KB | 40 | 1 | 16 | MFM |
| 400 KB | 80 | 2 | 10 | FM |
| 280 KB | 80 | 2 | 7 | FM |

Track 0 carries the directory and a system/info sector. Within that system
sector TR-DOS records a **disk-type byte** whose value identifies the geometry:
`0x16` double-sided 80-track, `0x17` double-sided 40-track, `0x18`
single-sided 80-track, `0x19` single-sided 40-track. MAME reads this byte (at
offset `0xe3` inside the sector for MFM disks, or `0x100` with inverted bits for
FM) and accepts values `0x16`–`0x19` to confirm the image. This is a validity
field deep inside the filesystem, not a fixed file-header magic, so there is no
Detection signature; images are recognised by size, extension and the TR-DOS
catalogue layout.

## References

- MAME loader:
  [`src/lib/formats/trd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/trd_dsk.cpp)
  ("TRD floppy disk image"; six 256-byte-sector geometries; disk-type byte
  `0x16`–`0x19` validated in the track-0 system sector).
- [TRD format — Sinclair Wiki (zxnet.co.uk)](https://sinclair.wiki.zxnet.co.uk/wiki/TRD_format)
  (headerless raw dump; 16x256-byte sectors; side-interleaved logical tracks;
  disk-type byte and directory in track 0).
- [TRD — Just Solve the File Format Problem](http://fileformats.archiveteam.org/wiki/TRD)
- [TR-DOS flat-file disk image — Kaitai Struct format gallery](https://formats.kaitai.io/tr_dos_image/)

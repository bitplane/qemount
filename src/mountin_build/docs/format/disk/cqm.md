---
title: CopyQM image
created: 1987
system: PC / generic floppy (Sydex CopyQM)
extensions: [".cqm", ".cqi", ".dsk"]
aliases:
  - CopyQM
  - CQM
related:
  - format/disk/imd
  - format/disk/teledisk
---

# CopyQM image

A compressed floppy-disk image written by **CopyQM**, a DOS disk-duplication
utility from Sydex Inc. (authored by Chuck Guzis), introduced around 1987.
CopyQM was a general-purpose tool for imaging and mass-duplicating diskettes of
many PC and non-PC geometries, so the format is not tied to a single computer
system; it stores whatever geometry was read from the source disk.

## Structure

Per the MAME loader, the file begins with a fixed 133-byte header followed by
RLE-compressed sector data. Header fields (little-endian) include:

| Offset | Field |
|--------|-------|
| 0x00 | Signature (`C`, `Q`, then `0x14`) |
| 0x03 | Sector size |
| 0x10 | Sectors per track |
| 0x12 | Number of heads |
| 0x58 | Mode (0 = DOS, 1 = blind, 2 = HFS) |
| 0x59 | Density (0 = DD, 1 = HD, 2 = ED) |
| 0x5B | Number of tracks |
| 0x6F | Comment length |
| 0x71 | Sector base + 1 |
| 0x74 | Interleave |
| 0x75 | Skew |

A variable-length comment follows the header. The disk payload is run-length
encoded: a signed 16-bit length introduces either a literal run (positive) or a
repeated byte (negative), so the body must be decompressed before the raw
sector image can be reconstructed.

## References

- MAME loader: [`src/lib/formats/cqm_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/cqm_dsk.cpp)
- [Dealing with CopyQM file format — Virtually Fun](https://virtuallyfun.com/2014/06/29/dealing-with-copyqm-file-format/)
- [CopyQM manual (Oct 1994) — bitsavers](https://www.bitsavers.org/pdf/sydex/CopyQM_Oct94.pdf)
- [CopyQM images — rio.early8bitz.de](https://rio.early8bitz.de/cqm/index.htm)

---
title: CHD (MAME)
created: 2001
related:
  - format/disk/raw
detect:
  - offset: 0
    type: string
    value: "MComprHD"
---

# CHD (Compressed Hunks of Data)

CHD was created by Aaron Giles around 2001 for the MAME project. It stores
compressed disk images (hard drives, CD-ROMs, LaserDiscs, GD-ROMs) for
arcade machine emulation. The format divides the image into fixed-size
"hunks" that are individually compressed.

## Characteristics

- Per-hunk compression (random access without full decompression)
- Multiple compression codecs (zlib, LZMA, FLAC, Huffman, AVHU)
- Parent/child delta images (store only differences)
- SHA-1 checksums per hunk
- Supports hard disk, CD-ROM, GD-ROM, and LaserDisc media
- Self-describing geometry metadata

## Structure

```
Header:
  Offset  Size  Field
  0       8     Magic ("MComprHD")
  8       4     Header length
  12      4     Version
  ...
```

Version-specific fields follow, including hunk size, total hunks,
compression type, and SHA-1 checksums.

## Versions

| Version | Notes |
|---------|-------|
| 1-2 | Early MAME |
| 3 | Added SHA-1 verification |
| 4 | Multiple compressor support |
| 5 | Current, improved compression |

## File Extension

`.chd`

## References

- [MAME Documentation: CHD](https://docs.mamedev.org/)

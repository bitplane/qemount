---
title: ARC
created: 1985
discontinued: 1989
detect:
  - offset: 0
    type: byte
    value: 0x1a
---

# ARC (SEA Archive)

ARC was created by Thom Henderson at System Enhancement Associates (SEA)
in 1985. It was the first widely-used archive format on DOS and dominated
BBS file distribution until ZIP replaced it. The format led to a famous
lawsuit when Phil Katz created a compatible tool (PKARC), which prompted
Katz to create the incompatible ZIP format instead.

## Characteristics

- Sequential archive (files stored one after another)
- Multiple compression methods evolved over versions
- 13-character MS-DOS filename per entry
- No directory support (flat archive)
- No encryption in original format

## Structure

Each member file entry:

| Offset | Size | Field |
|--------|------|-------|
| 0      | 1    | Magic (0x1A) |
| 1      | 1    | Compression method |
| 2      | 13   | Filename (null-terminated DOS 8.3) |
| 15     | 4    | Compressed size |
| 19     | 4    | File date/time (MS-DOS format) |
| 23     | 2    | CRC-16 |
| 25     | 4    | Original size |

Archive ends with a two-byte marker: 0x1A 0x00.

## Compression Methods

| ID | Method |
|----|--------|
| 1  | Stored (old) |
| 2  | Stored |
| 3  | Packed (RLE) |
| 4  | Squeezed (Huffman) |
| 5  | Crunched (LZW 9-bit) |
| 6  | Crunched (LZW 9-12 bit) |
| 7  | Crunched (LZW with reset) |
| 8  | Crunched (dynamic LZW) |
| 9  | Squashed (LZW 13-bit) |

## History

- 1985: ARC released by SEA
- 1986: Phil Katz creates PKARC (compatible clone)
- 1988: SEA sues Katz, wins
- 1989: Katz creates PKZIP (new incompatible format), ARC declines
- ARC format clones: ARCE, XARC, NARC, PAK (NoGate)

## References

- [Wikipedia: ARC (file format)](https://en.wikipedia.org/wiki/ARC_(file_format))

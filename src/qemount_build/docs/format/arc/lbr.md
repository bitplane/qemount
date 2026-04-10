---
title: LBR
created: 1982
discontinued: 1985
related:
  - format/arc/arc
  - format/fs/cpm
detect:
  - offset: 0
    type: string
    value: "\x00           \x00\x00"
---

# LBR (Library)

LBR was created by Gary P. Novosielski around 1982 for CP/M systems,
using the LU (Library Utility) program. It is the earliest widely-used
archive format for microcomputers, predating ARC by three years. LBR
files were the standard way to bundle files for distribution on CP/M
BBS systems.

## Characteristics

- Simple flat archive (no compression, no directories)
- 128-byte record alignment (CP/M sector size)
- Fixed-size directory at start of file
- 8.3 filenames (CP/M convention)
- No built-in compression (use squeeze/crunch externally)
- Maximum ~256 directory entries

## Structure

The file is divided into 128-byte records. The first N records form the
directory.

### Directory Entry (32 bytes)

| Offset | Size | Field |
|--------|------|-------|
| 0      | 1    | Status (0x00=active, 0xFE=deleted, 0xFF=unused) |
| 1      | 8    | Filename (space-padded) |
| 9      | 3    | Extension (space-padded) |
| 12     | 2    | Start record index (LE16) |
| 14     | 2    | Record count (LE16) |
| 16     | 2    | CRC-16 |
| 18     | 2    | Creation date |
| 20     | 2    | Last modified date |
| 22     | 2    | Creation time |
| 24     | 2    | Last modified time |
| 26     | 1    | Pad count (unused bytes in last record) |
| 27     | 5    | Reserved |

## Detection

The first directory entry (the directory itself) has status byte 0x00,
an 11-byte space-padded filename (all spaces for the directory entry),
followed by 0x00 0x00 for the start offset. This gives the pattern:
`\x00` + 11 spaces + `\x00\x00` at offset 0.

## File Extension

`.lbr`

## References

- Superseded by ARC (1985) which added compression

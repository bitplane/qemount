---
title: AIN
created: 1993
discontinued: 1996
---

# AIN

AIN is a DOS shareware archive format developed by InfoService Ltd. (later
Transas Marine Ltd.), a Russian company. It was distributed via FidoNet and
BBS systems in the early-to-mid 1990s. The compression methods are
proprietary and unpublished.

## Characteristics

- DOS-only archive tool
- Proprietary compression (methods unknown)
- Multi-volume spanning
- "Garbling" (encryption/obfuscation)
- Self-extracting archive support (AINSFX/AINEXT)
- Executable compression (AINEXE for DOS EXE files)
- Compressed index at end of file

## Structure

Archive header (24 bytes, little-endian):

| Offset | Size | Field |
|--------|------|-------|
| 0      | 1    | Unknown (observed 0x21) |
| 1      | 1    | /u setting (high nibble), /m setting (low nibble) |
| 2      | 1    | Unknown (observed 0) |
| 3      | 1    | Flags (0x80=garbled, 0x40=multi-volume) |
| 4      | 2    | Garble data (0 if not garbled) |
| 6      | 2    | Volume number (0=first) |
| 8      | 2    | Number of member files |
| 10     | 4    | Archive timestamp |
| 14     | 4    | Index location |
| 18     | 2    | Index checksum (sum of bytes from index to EOF) |
| 20     | 2    | Unknown (observed 0) |
| 22     | 2    | Header checksum (sum of first 22 bytes XOR 0x5555) |

File data follows the header. The index is at the end of the file and is
compressed.

## Detection

No magic number. The format is identified by validating the header and
index checksums. A heuristic: first byte is 0x21, bytes 2-7 are
`00 00 00 00 00 00` for default single-volume ungarbled archives.

AINEXE-compressed executables have ASCII `AIN2` at offset 32.

## Versions

| Version | Date | Notes |
|---------|------|-------|
| 2.1 | 1993-07 | Earliest known version |
| 2.2 | 1993-10 | Incompatible with 2.0 format |
| 2.23 | ~1994 | Added AINSFX self-extractor |
| 2.30 | ~1996 | |
| 2.32 | ~1996 | Last known version, AINEXT as self-extractor |

## References

- [Archive Team wiki: AIN](http://justsolve.archiveteam.org/wiki/AIN)
- [old-dos.ru: AIN versions](http://old-dos.ru/index.php?page=files&mode=files&do=show&id=698)

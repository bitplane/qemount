---
title: OLE Compound Document
created: 1993
detect:
  - offset: 0
    type: string
    value: "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"
---

# OLE Compound Document (Structured Storage)

Microsoft's OLE2 Compound Document format was introduced around 1993 as
part of OLE2/COM. It provides a filesystem-within-a-file — a FAT-like
structure with directories and streams inside a single file. Used as the
container for Office 97-2003 documents and many other Microsoft formats.

The 8-byte magic `D0CF11E0A1B11AE1` is a Microsoft in-joke — it reads
as "DOCFILE" with high bits set.

## Characteristics

- Internal FAT-like filesystem with directory entries and streams
- 512-byte or 4096-byte sectors
- Mini-stream for small data (< 4096 bytes)
- Double-indirect FAT (DIFAT) for large files
- Transactional support (two FAT copies)

## Structure

```
Header (512 bytes):
  Offset  Size  Field
  0       8     Magic (D0 CF 11 E0 A1 B1 1A E1)
  8       16    CLSID (usually zero)
  24      2     Minor version
  26      2     Major version (3 or 4)
  28      2     Byte order (0xFFFE = little-endian)
  30      2     Sector size power (9=512, 12=4096)
  32      2     Mini-sector size power (6=64)
  ...
```

## Formats Using OLE

| Extension | Application |
|-----------|-------------|
| `.doc` | Word 97-2003 |
| `.xls` | Excel 97-2003 |
| `.ppt` | PowerPoint 97-2003 |
| `.msi` | Windows Installer |
| `.msg` | Outlook message |
| `.thumbs.db` | Windows thumbnail cache |
| `.pub` | Publisher |
| `.vsd` | Visio |

## File Extension

Various — the container itself has no standard extension.

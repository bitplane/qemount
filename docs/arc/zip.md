---
title: ZIP
created: 1989
related:
  - arc/tar
detect:
  - offset: 0
    type: le32
    value: 0x04034b50
    name: local_file_header
---

# ZIP

ZIP was created by Phil Katz (PKWARE) in 1989. It became the dominant
archive format on DOS/Windows and is now used everywhere including
Java JARs, Office documents, and Android APKs.

## Characteristics

- Per-file compression
- Random access (central directory at end)
- Cross-platform
- Encryption support (weak original, AES later)
- Maximum 4GB files (ZIP64 for larger)

## Structure

```
[Local file header 1]
[File data 1]
[Data descriptor 1]
...
[Local file header n]
[File data n]
[Data descriptor n]
[Central directory]
[End of central directory]
```

## Signatures

| Signature | Hex | Meaning |
|-----------|-----|---------|
| PK\x03\x04 | 0x04034b50 | Local file header |
| PK\x01\x02 | 0x02014b50 | Central directory |
| PK\x05\x06 | 0x06054b50 | End of central dir |
| PK\x06\x06 | 0x06064b50 | ZIP64 end |
| PK\x07\x08 | 0x08074b50 | Data descriptor |

## Compression Methods

| ID | Method |
|----|--------|
| 0 | Store (none) |
| 8 | Deflate |
| 9 | Deflate64 |
| 12 | BZIP2 |
| 14 | LZMA |
| 93 | Zstandard |
| 95 | XZ |

## ZIP-based Formats

Many formats are ZIP with specific contents:
- `.jar` - Java Archive
- `.docx/.xlsx/.pptx` - Office Open XML
- `.odt/.ods/.odp` - OpenDocument
- `.apk` - Android Package
- `.epub` - E-book
- `.xpi` - Firefox extension

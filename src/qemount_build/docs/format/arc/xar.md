---
title: XAR
created: 2005
detect:
  - offset: 0
    type: be32
    value: 0x78617221
---

# XAR (eXtensible ARchive)

XAR was created as part of the OpenDarwin project in 2005. Apple adopted
it as the format for macOS installer packages (.pkg). The table of
contents is stored as compressed XML, making it extensible and
human-inspectable.

## Characteristics

- XML table of contents (gzip-compressed)
- Pluggable compression (gzip, bzip2, lzma, none)
- Pluggable checksums (SHA-1, SHA-256, MD5)
- Digital signatures
- File forks and extended attributes
- Heap-based data storage

## Structure

```
Header (28 bytes):
  Offset  Size  Field
  0       4     Magic (0x78617221 = "xar!")
  4       2     Header size
  6       2     Version (1)
  8       8     TOC compressed size
  16      8     TOC uncompressed size
  24      4     Checksum algorithm
```

After the header: compressed XML TOC, then the data heap containing
file contents at offsets referenced by the TOC.

## Usage

- `.pkg` — macOS installer packages
- `.xar` — generic archives
- Superseded `.pax` for Apple software distribution

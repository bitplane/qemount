---
title: lzop
created: 1997
related:
  - format/arc/gzip
  - format/arc/lz4
detect:
  - offset: 0
    type: string
    value: "\x89LZO\x00\x0d\x0a\x1a\x0a"
---

# lzop

lzop was created by Markus Oberhumer in 1997. It uses LZO compression,
prioritising speed over compression ratio — similar philosophy to lz4.
The container format is inspired by gzip.

## Characteristics

- Very fast compression and decompression
- Lower compression ratio than gzip/bzip2/xz
- Block-level compression with checksums
- Multiple LZO algorithm variants
- Designed for speed-critical applications

## Structure

```
Header:
  Offset  Size  Field
  0       9     Magic (89 4C 5A 4F 00 0D 0A 1A 0A)
  9       2     Version
  11      2     Library version
  13      2     Version needed to extract
  15      1     Method
  16      1     Level
  17      4     Flags
  ...
```

The magic mirrors the PNG-style signature with high-bit byte, format
name, DOS and Unix line endings, and EOF marker.

## File Extension

`.lzo`

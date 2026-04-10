---
title: lzip
created: 2008
related:
  - format/arc/lzma
  - format/arc/xz
detect:
  - offset: 0
    type: string
    value: "LZIP"
---

# lzip

lzip was created by Antonio Diaz Diaz in 2008. It uses LZMA compression
with a simpler container format than xz, designed for long-term archival.
Adopted by the GNU project as a distribution format.

## Characteristics

- LZMA compression (same algorithm as xz/7z)
- Simple, well-defined container format
- CRC-32 integrity checking
- Designed for data integrity and long-term archival
- Single-stream (no multi-file support — use with tar)

## Structure

```
Header:
  Offset  Size  Field
  0       4     Magic ("LZIP")
  4       1     Version (1)
  5       1     Dictionary size (encoded)

Trailer (20 bytes at end):
  CRC-32, data size, member size
```

## File Extension

`.lz`

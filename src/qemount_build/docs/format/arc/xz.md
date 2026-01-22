---
title: xz
created: 2009
related:
  - format/arc/tar
  - format/arc/gzip
  - format/arc/bzip2
detect:
  - offset: 0
    type: string
    value: "\xFD7zXZ\x00"
---

# XZ

XZ Utils was created by Lasse Collin in 2009 as a successor to LZMA Utils.
It provides excellent compression ratios using the LZMA2 algorithm.

## Characteristics

- Single file compression
- LZMA2 algorithm (improved LZMA)
- Better compression than gzip and bzip2
- Slower compression, fast decompression
- Integrity checking (CRC32/CRC64/SHA-256)
- Usually paired with tar for archives

## Structure

**Stream Header (12 bytes):**
```
Offset  Size  Field
0       6     Magic (0xFD "7zXZ" 0x00)
6       2     Stream flags
8       4     CRC32 of flags
```

**Blocks:**
- Block header
- Compressed data (LZMA2)
- Block padding (to 4-byte boundary)

**Index:**
- Records of uncompressed/compressed sizes
- Used for random access

**Stream Footer (12 bytes):**
```
Offset  Size  Field
0       4     CRC32
4       4     Backward size
8       2     Stream flags
10      2     Magic (0x59 0x5A = "YZ")
```

## Check Types

| ID | Type   | Size    |
|----|--------|---------|
| 0  | None   | 0       |
| 1  | CRC32  | 4 bytes |
| 4  | CRC64  | 8 bytes |
| 10 | SHA256 | 32 bytes|

## Related Formats

- **LZMA** - raw LZMA stream (different magic: 0x5D)
- **7z** - 7-Zip archive format (uses LZMA/LZMA2)
- **pixz** - parallel indexed xz
- **pxz** - parallel xz

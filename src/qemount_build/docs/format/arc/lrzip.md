---
title: lrzip
created: 2006
related:
  - format/arc/lzip
  - format/arc/bzip2
detect:
  - offset: 0
    type: string
    value: "LRZI"
---

# lrzip (Long Range ZIP)

lrzip was created by Con Kolivas in 2006. It combines rzip's long-range
redundancy detection with LZMA, LZO, ZPAQ, or bzip2 backend compression.
Particularly effective on large files with repeated patterns at long
distances (e.g. VM images, database dumps).

## Characteristics

- Long-range redundancy detection (rzip algorithm)
- Multiple backend compressors (LZMA, LZO, ZPAQ, bzip2, none)
- Optional AES-128 encryption
- Excellent on large files with distant repetitions
- Parallelised compression
- Not suitable for streaming (needs seekable input)

## Structure

```
Header:
  Offset  Size  Field
  0       4     Magic ("LRZI")
  4       1     Major version
  5       1     Minor version
  6-21    var   Stream metadata
  22      1     Encryption flag
```

## File Extension

`.lrz`

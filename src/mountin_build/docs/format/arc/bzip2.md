---
title: bzip2
created: 1996
related:
  - format/arc/tar
  - format/arc/gzip
detect:
  - offset: 0
    type: string
    value: "BZh"
---

# bzip2

bzip2 was created by Julian Seward in 1996. It uses the Burrows-Wheeler
transform for better compression than gzip, at the cost of speed.

## Characteristics

- Single file compression
- Burrows-Wheeler transform + Huffman coding
- Better compression ratio than gzip
- Slower compression/decompression
- Usually paired with tar for archives

## Structure

**Header:**
```
Offset  Size  Field
0       2     Magic "BZ"
2       1     Version ('h' = Huffman)
3       1     Block size ('1'-'9', multiply by 100KB)
```

**Stream:**
- Block header: 0x314159265359 (pi digits)
- Compressed data blocks
- Stream footer: 0x177245385090 (sqrt(pi) digits)

## Block Sizes

| Char | Block Size | Memory Use |
|------|------------|------------|
| '1'  | 100 KB     | ~1 MB      |
| '9'  | 900 KB     | ~8 MB      |

Default is '9' for best compression.

## Related Formats

- **pbzip2** - parallel bzip2
- **lbzip2** - parallel bzip2 (alternative)
- **bzip3** - successor format (different magic)

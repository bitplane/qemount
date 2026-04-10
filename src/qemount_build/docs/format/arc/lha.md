---
title: LHA
created: 1988
detect:
  any:
    - offset: 2
      type: string
      value: "-lh"
    - offset: 2
      type: string
      value: "-lz"
---

# LHA (LHarc / LZH)

LHA was created by Haruyasu Yoshizaki (Yoshi) in 1988 in Japan. It was
the dominant archive format in Japan and on the Amiga throughout the
1990s. Originally called LHarc, renamed to LHA after a naming dispute.

## Characteristics

- LZSS + Huffman compression
- Multiple compression methods (-lh0- through -lh7-)
- Directory support
- OS-specific extended headers
- Widely used for Amiga software distribution

## Structure

Each file has a header starting at variable positions:

```
Level 0/1 header:
  Offset  Size  Field
  0       1     Header size
  1       1     Checksum
  2       5     Method ID (e.g. "-lh5-")
  7       4     Compressed size
  11      4     Original size
  15      4     Timestamp (MS-DOS format)
  19      1     Attributes
  20      1     Level (0 or 1)
  21+     var   Filename
```

The method ID at offset 2 is the detection signature:
`-lh?-` or `-lz?-` where `?` indicates the compression method.

## Compression Methods

| ID    | Method |
|-------|--------|
| -lh0- | Stored (no compression) |
| -lh1- | LZS + 4K sliding window |
| -lh5- | LZS + 8K sliding window (most common) |
| -lh6- | LZS + 32K sliding window |
| -lh7- | LZS + 64K sliding window |
| -lzs- | LZ77, 2K window |
| -lz5- | LZ77, 4K window |

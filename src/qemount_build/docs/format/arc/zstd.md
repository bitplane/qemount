---
title: Zstandard
created: 2016
related:
  - format/arc/tar
  - format/arc/xz
detect:
  - offset: 0
    type: le32
    value: 0xFD2FB528
---

# Zstandard (zstd)

Zstandard was created by Yann Collet at Facebook in 2016. It provides
compression ratios comparable to zlib/gzip with much faster speeds.

## Characteristics

- Single file compression
- LZ77 + Huffman/FSE entropy coding
- Very fast compression and decompression
- Scalable compression levels (1-22)
- Dictionary support for small data
- Used by Linux kernel, package managers

## Structure

**Frame Header:**
```
Offset  Size  Field
0       4     Magic (0x28B52FFD little-endian)
4       1     Frame header descriptor
5       0-5   Window descriptor (optional)
...           Dictionary ID (optional)
...           Frame content size (optional)
```

**Frame Header Descriptor (byte 4):**
```
Bits 7-6: Frame_Content_Size_flag
Bits 5:   Single_Segment_flag
Bits 4:   Unused
Bits 3:   Reserved
Bits 2:   Content_Checksum_flag
Bits 1-0: Dictionary_ID_flag
```

**Blocks:**
- Block header (3 bytes)
- Compressed/raw/RLE data
- Repeat until last block

**Optional Checksum:**
- XXH64 hash (4 bytes, lower 32 bits)

## Compression Levels

| Level | Speed    | Ratio |
|-------|----------|-------|
| 1     | Fastest  | Low   |
| 3     | Default  | Good  |
| 19    | Slow     | Best  |
| 22    | Slowest  | Max   |

## Related Formats

- **pzstd** - parallel zstd
- **zstd --long** - long range mode for large files

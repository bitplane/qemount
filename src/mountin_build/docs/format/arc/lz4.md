---
title: LZ4
created: 2011
related:
  - format/arc/zstd
  - format/arc/gzip
detect:
  - offset: 0
    type: le32
    value: 0x184D2204
---

# LZ4

LZ4 was created by Yann Collet in 2011, focusing on extremely fast
compression and decompression speeds rather than ratio.

## Characteristics

- Single file compression (frame format)
- LZ77-based algorithm
- Extremely fast decompression (GB/s)
- Fast compression
- Lower ratio than gzip/zstd
- Used in ZFS, Linux kernel, real-time applications

## Structure

**Frame Header:**
```
Offset  Size  Field
0       4     Magic (0x184D2204 little-endian)
4       1     FLG byte
5       1     BD byte
6       0-8   Content size (optional)
...     1     Header checksum (xxHash-32 >> 8)
```

**FLG Byte:**
```
Bits 7-6: Version (01 = current)
Bit 5:    Block Independence flag
Bit 4:    Block Checksum flag
Bit 3:    Content Size flag
Bit 2:    Content Checksum flag
Bit 1:    Reserved
Bit 0:    DictID flag
```

**BD Byte:**
```
Bits 7:   Reserved
Bits 6-4: Block Max Size
Bits 3-0: Reserved
```

**Block Max Sizes:**
| Value | Size    |
|-------|---------|
| 4     | 64 KB   |
| 5     | 256 KB  |
| 6     | 1 MB    |
| 7     | 4 MB    |

**Data Blocks:**
- Block size (4 bytes, LE)
- Compressed data
- Optional block checksum (4 bytes)

**End Mark:**
- 0x00000000 (4 bytes)

**Optional Content Checksum:**
- xxHash-32 (4 bytes)

## Legacy Format

Older LZ4 streams without framing start directly with compressed
blocks. The frame format (magic 0x184D2204) is preferred.

## Related Tools

- **lz4** - Reference implementation
- **lz4c** - CLI tool
- **plz4** - Parallel lz4

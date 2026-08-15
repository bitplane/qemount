---
title: LZMA
created: 1998
related:
  - format/arc/xz
  - format/arc/7z
detect:
  - offset: 0
    type: byte
    value: 0x5D
    then:
      - offset: 1
        type: byte
        op: "<"
        value: 0xE1
---

# LZMA

LZMA (Lempel-Ziv-Markov chain Algorithm) was created by Igor Pavlov
for the 7-Zip archiver. This is the raw stream format, later wrapped
by xz with better framing.

## Characteristics

- Single file compression
- LZ77 + range coding
- Very high compression ratio
- Slower compression, moderate decompression
- Used in 7-Zip solid archives
- Superseded by xz for most uses

## Structure

**Header (13 bytes):**
```
Offset  Size  Field
0       1     Properties byte (lc/lp/pb encoded)
1       4     Dictionary size (LE32)
5       8     Uncompressed size (LE64, -1 if unknown)
```

**Properties Byte:**
```
Value = lc + lp * 9 + pb * 45
Where:
  lc: Literal context bits (0-8, default 3)
  lp: Literal position bits (0-4, default 0)
  pb: Position bits (0-4, default 2)

Default properties byte: 0x5D (lc=3, lp=0, pb=2)
```

**Dictionary Sizes:**
| Bytes    | Size     |
|----------|----------|
| 00001000 | 4 KB     |
| 00100000 | 1 MB     |
| 01000000 | 16 MB    |
| 02000000 | 32 MB    |

**Compressed Data:**
- Range-coded LZMA stream
- No framing or checksums (unlike xz)

## Detection Notes

LZMA doesn't have a true magic number. Detection relies on:
- Properties byte typically 0x5D (but can be 0x00-0xE0)
- Dictionary size being reasonable power of 2

## Related Formats

- **xz** - LZMA2 with proper framing and checksums
- **7z** - Archive format using LZMA/LZMA2
- **lzip** - Alternative LZMA wrapper

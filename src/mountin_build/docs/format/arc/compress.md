---
title: Unix compress
created: 1983
related:
  - format/arc/gzip
detect:
  - offset: 0
    type: le16
    value: 0x9D1F
---

# Unix compress (.Z)

The original Unix compress utility, created in 1983 by Spencer Thomas
and others. Uses LZW compression algorithm.

## Characteristics

- Single file compression
- LZW (Lempel-Ziv-Welch) algorithm
- Historically ubiquitous on Unix systems
- Replaced by gzip due to LZW patent issues
- Still found in old archives and backups

## Structure

**Header (3 bytes):**
```
Offset  Size  Field
0       2     Magic (0x1F 0x9D)
2       1     Flags
```

**Flags (byte 2):**
```
Bits 0-4: Max bits (9-16, typically 16)
Bits 5-6: Reserved
Bit 7:    Block mode (reset dictionary on code 256)
```

**Data:**
- LZW compressed stream
- Variable-width codes (9 to max_bits)
- LSB-first bit packing

## Max Bits

| Value | Max Codes | Memory |
|-------|-----------|--------|
| 12    | 4096      | ~32 KB |
| 14    | 16384     | ~128 KB|
| 16    | 65536     | ~512 KB|

Default is typically 16 bits.

## Historical Note

LZW was patented by Unisys, causing the "GIF/LZW controversy"
of the 1990s. This led to gzip's creation as a patent-free
alternative. The patents expired in 2003-2004.

## File Extension

`.Z` (uppercase) - commonly confused with `.z` (pack format).

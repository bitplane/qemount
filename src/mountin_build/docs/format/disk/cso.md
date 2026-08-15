---
title: CSO
created: 2005
related:
  - format/fs/iso9660
detect:
  - offset: 0
    type: string
    value: "CISO"
---

# CSO (Compressed ISO)

CSO was created around 2005 in the PSP homebrew scene for compressing
ISO-9660 disc images. The compressed images can be read directly by PSP
emulators and custom firmware without full decompression.

## Characteristics

- Block-level compression (each block independently decompressible)
- Random access (block index at start of file)
- Deflate compression (v1) or LZ4/zstd (v2)
- Typically ~40-70% compression ratio on game data
- Sector size: 2048 bytes (ISO-9660 standard)

## Structure

```
Header (24 bytes):
  Offset  Size  Field
  0       4     Magic ("CISO" = 43 49 53 4F)
  4       4     Header size (v2) / Uncompressed size low (v1)
  8       8     Total uncompressed size
  16      4     Block size (usually 2048)
  20      1     Version (1 or 2)
  21      1     Alignment
  22      2     Reserved
```

Followed by a block index (array of uint32 offsets), then compressed
block data.

## Variants

Three formats share the `CISO` magic but differ internally:

| Variant | Platform | Distinguishing field |
|---------|----------|---------------------|
| PSP CSO | PlayStation Portable | offset 0x10 = 0x800 |
| GameCube/Wii CISO | Nintendo | offset 0x04 = 0x200000 |
| Compact ISO | Pismo | Neither of above |

## References

- Used by PPSSPP, custom PSP firmware, Dolphin emulator

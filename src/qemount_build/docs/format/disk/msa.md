---
title: MSA (Atari ST)
created: 1989
related:
  - format/disk/raw
  - format/fs/gemdos
detect:
  - offset: 0
    type: be16
    value: 0x0e0f
---

# MSA (Magic Shadow Archiver)

MSA is a compressed floppy disk image format for the Atari ST, created
by the Magic Shadow Archiver utility around 1989. It stores complete
floppy images with optional per-track RLE compression, significantly
reducing the size of disk images with empty space.

## Characteristics

- Per-track RLE compression
- Stores complete floppy geometry (sectors/track, sides, track range)
- Supports single and double-sided disks
- Simple format, easy to implement
- Standard format for Atari ST disk preservation

## Structure

```
Header (10 bytes):
  Offset  Size  Field
  0       2     Magic (0x0E0F, big-endian)
  2       2     Sectors per track
  4       2     Sides (0=single, 1=double)
  6       2     Starting track
  8       2     Ending track
```

Followed by track data. Each track is preceded by a 2-byte compressed
length. If compressed length equals uncompressed track size, the data
is stored raw. Otherwise, RLE compression is used (marker byte 0xE5,
followed by fill byte, then 2-byte repeat count).

## File Extension

`.msa`

## References

- Used by Hatari, Steem, and other Atari ST emulators

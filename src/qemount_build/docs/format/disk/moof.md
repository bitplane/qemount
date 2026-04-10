---
title: MOOF (Applesauce)
created: 2019
related:
  - format/disk/raw
  - format/disk/diskcopy42
detect:
  - offset: 0
    type: string
    value: "MOOF\xFF\x0A\x0D\x0A"
---

# MOOF (Applesauce Disk Image)

MOOF was created around 2019 by the Applesauce project for preserving
Macintosh floppy disks (400K, 800K, 1.44MB). It captures flux-level
data from Mac GCR and MFM encoded disks, preserving copy protection
and non-standard formatting that raw sector dumps would lose.

## Characteristics

- Flux-level floppy preservation
- Mac GCR and MFM encoding support
- 400K, 800K, and 1.44MB Mac floppy formats
- Per-track data with timing information
- Chunk-based file structure (like IFF/PNG)
- CRC-32 checksums

## Structure

```
Header (8 bytes):
  Offset  Size  Field
  0       4     Magic ("MOOF")
  4       4     Signature (FF 0A 0D 0A)
```

The signature bytes follow the PNG convention — high-bit byte, LF,
CR+LF — to detect transmission corruption.

Followed by typed chunks, each with a 4-byte type, 4-byte length,
and chunk data.

## File Extension

`.moof`

## References

- [Applesauce FDC](https://applesaucefdc.com/)
- Companion to the WOZ format (Apple II equivalent)

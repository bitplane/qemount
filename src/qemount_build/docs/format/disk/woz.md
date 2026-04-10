---
title: WOZ
created: 2018
related:
  - format/disk/moof
  - format/disk/raw
detect:
  any:
    - offset: 0
      type: string
      value: "WOZ1"
    - offset: 0
      type: string
      value: "WOZ2"
---

# WOZ (Applesauce Disk Image)

WOZ was created by John K. Morris in 2018 for the Applesauce project.
It captures flux-level data from Apple II floppy disks, preserving
copy protection and non-standard formatting. WOZ is the Apple II
counterpart to the MOOF format (which handles Mac floppies).

## Characteristics

- Flux-level floppy preservation
- Apple II 5.25" and 3.5" disk support
- GCR and MFM encoding
- Per-track timing data (WOZ 2.0)
- Chunk-based file structure
- Metadata (creator, platform, write protection)
- CRC-32 checksums

## Structure

```
Header (12 bytes):
  Offset  Size  Field
  0       4     Magic ("WOZ1" or "WOZ2")
  4       4     Signature (FF 0A 0D 0A)
  8       4     CRC-32 of remaining file
```

The signature bytes follow the PNG convention — high-bit byte, LF,
CR+LF — to detect line-ending corruption.

Followed by typed chunks: INFO, TMAP, TRKS, WRIT, META.

## Versions

| Version | Year | Additions |
|---------|------|-----------|
| WOZ 1.0 | 2018 | Initial format |
| WOZ 2.0 | 2019 | Per-track timing, 3.5" support |

## File Extension

`.woz`

## References

- [Applesauce FDC](https://applesaucefdc.com/)
- Supported by MAME, AppleWin, and other Apple II emulators

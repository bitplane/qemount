---
title: Apple DiskCopy 4.2
created: 1988
discontinued: 2003
related:
  - format/disk/dmg
  - format/disk/raw
detect:
  - offset: 0x52
    type: be16
    value: 0x0100
---

# Apple DiskCopy 4.2

DiskCopy 4.2 is Apple's classic Macintosh disk image format, used from
the late 1980s through the Mac OS 9 era. It was the standard format for
distributing floppy disk images. DiskCopy 6.x later introduced the NDIF
format, which evolved into the modern DMG (UDIF) format in Mac OS X.

## Characteristics

- Stores complete floppy disk images (400K, 800K, 1.4MB)
- Includes data fork and tag bytes
- CRC-32 checksums for data and tags
- Pascal string disk name in header
- No compression in 4.2 format

## Structure

| Offset | Size | Field |
|--------|------|-------|
| 0      | 1    | Disk name length (Pascal string) |
| 1      | 63   | Disk name |
| 0x40   | 4    | Data size |
| 0x44   | 4    | Tag size |
| 0x48   | 4    | Data checksum |
| 0x4C   | 4    | Tag checksum |
| 0x50   | 1    | Disk format (0=400K, 1=800K, 2=720K, 3=1440K) |
| 0x51   | 1    | Format byte (0x12=Mac 400K, 0x22=Mac 800K, 0x24=1.4M) |
| 0x52   | 2    | Magic (0x0100) |
| 0x54   | var  | Data fork |
| ...    | var  | Tag bytes |

## Detection

The magic `0x0100` at offset 0x52 combined with structural validation:
disk name length at offset 0 must be < 64, and data size at offset 0x40
must be a valid floppy size (400KB-64MB).

## History

- 1984: DiskCopy 1.0 for Macintosh 128K
- 1988: DiskCopy 4.2 format standardised
- 1996: DiskCopy 6.x adds NDIF format
- 2001: Mac OS X introduces UDIF (DMG), superseding DiskCopy
- 2003: DiskCopy discontinued

## References

- Mac type `dImg`, creator `dCpy`

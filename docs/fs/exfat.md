---
title: exFAT
type: fs
created: 2006
related:
  - fs/fat32
  - fs/ntfs
detect:
  - offset: 0x03
    type: string
    value: "EXFAT   "
    then:
      - offset: 0x1FE
        type: le16
        value: 0xAA55
      - offset: 0x68
        type: u8
        name: version_major
      - offset: 0x69
        type: u8
        name: version_minor
---

# exFAT (Extended FAT)

exFAT was developed by Microsoft in 2006 as a modern replacement for FAT32,
designed for flash media. It removes FAT32's 4GB file size limit while
maintaining simplicity and broad compatibility.

## Characteristics

- 32-bit cluster addresses (practical limit ~128 PB)
- Maximum volume size: 128 PB
- Maximum file size: 16 EB (effectively unlimited)
- Long filenames up to 255 UTF-16 characters
- Timestamps with 10ms precision and UTC offset
- No journaling (but has transaction-safe metadata)
- Free space bitmap (faster than FAT scanning)
- Optional TexFAT (transaction-safe FAT)

## Structure

- Boot sector at offset 0
- OEM label "EXFAT" at offset 0x03
- Boot signature 0xAA55 at offset 0x1FE
- Main and backup boot regions
- FAT region (single FAT typically)
- Cluster heap (data area)
- Allocation bitmap file
- Upcase table file

## Key Fields

| Offset | Size | Field |
|--------|------|-------|
| 0x03 | 8 | OEM name ("EXFAT   ") |
| 0x40 | 8 | Partition offset |
| 0x48 | 8 | Volume length (sectors) |
| 0x58 | 4 | Cluster count |
| 0x68 | 1 | Version major |
| 0x69 | 1 | Version minor |
| 0x6C | 1 | Bytes per sector (power of 2) |
| 0x6D | 1 | Sectors per cluster (power of 2) |

## Adoption

- SDXC cards (mandatory for > 32GB)
- USB drives (large files)
- Cross-platform exchange (macOS, Windows, Linux)
- Royalty-free since 2019 (Microsoft opened specification)

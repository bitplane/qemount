---
title: FAT32
type: fs
created: 1996
related:
  - fs/fat12
  - fs/fat16
  - fs/exfat
detect:
  - offset: 0x1FE
    type: le16
    value: 0xAA55
    then:
      - offset: 0x52
        type: string
        length: 8
        value: "FAT32   "
      - offset: 0x11
        type: le16
        value: 0
      - offset: 0x16
        type: le16
        value: 0
---

# FAT32

FAT32 was introduced with Windows 95 OSR2 in 1996, using 28-bit cluster
addresses (4 bits reserved) for larger volume support. It remains the most
widely compatible filesystem for removable media.

## Characteristics

- 28-bit cluster addresses (max ~268 million clusters)
- Maximum volume size: 2 TB (8 TB with 32KB sectors)
- Maximum file size: 4 GB minus 1 byte (2^32 - 1 bytes)
- Long filenames (up to 255 UTF-16 characters via VFAT)
- Root directory is a regular cluster chain (not fixed)
- No permissions, journaling, or encryption

## Structure

- Boot sector with extended BPB at offset 0
- Boot signature 0xAA55 at offset 0x1FE
- FS Information sector (free cluster hints)
- Backup boot sector (usually sector 6)
- Two FAT copies
- Root directory as cluster chain (starts at cluster 2)

## Detection

Identified by:
- Root entries (0x11) = 0 (root is a cluster chain)
- Sectors per FAT (0x16) = 0 (use 32-bit field at 0x24)
- "FAT32" string at offset 0x52
- Cluster count > 65,524

## Key Fields (Extended BPB)

| Offset | Size | Field |
|--------|------|-------|
| 0x24 | 4 | Sectors per FAT (32-bit) |
| 0x2C | 4 | Root directory cluster |
| 0x30 | 2 | FS Info sector |
| 0x32 | 2 | Backup boot sector |

## Use Cases

- USB flash drives
- SD cards
- Cross-platform file exchange
- UEFI System Partition (ESP)

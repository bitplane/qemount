---
title: FAT16
created: 1984
discontinued: 2006
related:
  - format/fs/fat12
  - format/fs/fat32
detect:
  # FAT16: jump + nop + boot sig + valid media + larger volume + not FAT32
  - offset: 0
    type: byte
    value: 0xEB
    then:
      - offset: 2
        type: byte
        value: 0x90
        then:
          - offset: 0x1FE
            type: le16
            value: 0xAA55
            then:
              - offset: 0x15
                type: byte
                op: ">="
                value: 0xF0
                then:
                  # Sectors per FAT (16-bit) > 0 means not FAT32
                  - offset: 0x16
                    type: le16
                    op: ">"
                    value: 0
                    then:
                      # Total sectors > FAT12 threshold
                      - offset: 0x13
                        type: le16
                        op: ">"
                        value: 32680
---

# FAT16

FAT16 was introduced with MS-DOS 3.0 in 1984, extending FAT12's cluster
addresses to 16 bits for larger hard disk support. It became the standard
DOS and Windows 3.x/95 filesystem.

## Characteristics

- 16-bit cluster addresses (max 65,524 clusters)
- Maximum volume size: 2 GB (4 GB with 64KB clusters)
- Maximum file size: 2 GB
- 8.3 filenames (VFAT adds long names in Windows 95+)
- Case-insensitive filenames
- No permissions or ownership
- No journaling

## Structure

- Boot sector with BPB at offset 0
- Boot signature 0xAA55 at offset 0x1FE
- Two FAT copies (configurable)
- Fixed-size root directory (512 entries typical)
- Data clusters

## Detection

FAT type is determined by cluster count:
- 4,085 to 65,524 clusters → FAT16
- The string "FAT16" at offset 0x36 is informational

## Key Fields (BPB)

| Offset | Size | Field                  |
|--------|------|------------------------|
| 0x0B   | 2    | Bytes per sector       |
| 0x0D   | 1    | Sectors per cluster    |
| 0x0E   | 2    | Reserved sectors       |
| 0x10   | 1    | Number of FATs         |
| 0x11   | 2    | Root directory entries |
| 0x16   | 2    | Sectors per FAT        |

## Legacy

Replaced by FAT32 for large volumes. Still used for small partitions,
USB drives, and embedded systems where simplicity is valued.

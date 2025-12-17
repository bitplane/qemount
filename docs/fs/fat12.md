---
title: FAT12
type: fs
created: 1977
related:
  - fs/fat16
  - fs/fat32
detect:
  # FAT detection is complex - based on BPB fields not simple magic.
  # FAT12 is determined by cluster count < 4085, but we can use heuristics.
  - offset: 0x1FE
    type: le16
    value: 0xAA55
    then:
      - offset: 0x36
        type: string
        length: 8
        value: "FAT12   "
---

# FAT12

FAT12 is the original File Allocation Table filesystem, developed by Microsoft
(Bill Gates and Marc McDonald) in 1977 for Microsoft Disk BASIC. It uses 12-bit
cluster addresses and was designed for floppy disks.

## Characteristics

- 12-bit cluster addresses (max 4,084 clusters)
- Maximum volume size: ~16 MB (practical), 32 MB (theoretical)
- Maximum file size: 32 MB (limited by 16-bit sector count)
- 8.3 filenames (8 chars + 3 char extension)
- No timestamps on directories
- No permissions or ownership

## Structure

- Boot sector at offset 0 with BPB (BIOS Parameter Block)
- Boot signature 0xAA55 at offset 0x1FE
- FAT tables (usually 2 copies) follow boot sector
- Root directory (fixed size, immediately after FATs)
- Data area (clusters)

## Detection

FAT type is determined by cluster count, not a magic number:
- Clusters < 4,085 → FAT12
- The string "FAT12" at offset 0x36 is informational, not definitive

## Use Cases

- Floppy disks (360KB, 720KB, 1.44MB)
- Small flash media
- Boot sectors and UEFI system partitions (sometimes)

## Legacy

First filesystem for MS-DOS 1.0 (1981). Still supported everywhere for
backward compatibility with floppy disk images.

---
title: Protective MBR
created: 2000
related:
  - pt/mbr
  - pt/gpt
detect:
  - offset: 510
    type: le16
    value: 0xAA55
    then:
      - offset: 0x1C2
        type: u8
        value: 0xEE
        name: gpt_protective
---

# Protective MBR

A Protective MBR is part of the GPT specification. It contains a single
partition entry of type 0xEE covering the entire disk, preventing
MBR-only tools from seeing the disk as empty.

## Purpose

- Prevents MBR tools from treating GPT disk as unpartitioned
- Stops accidental overwriting of GPT structures
- Provides backward compatibility indicator
- Required by UEFI/GPT specification

## Structure

```
Offset  Size  Description
0       446   Boot code (optional)
446     16    Partition 1 (type 0xEE, covers whole disk)
462     16    Partition 2 (zeros)
478     16    Partition 3 (zeros)
494     16    Partition 4 (zeros)
510     2     Signature (0xAA55)
```

## Partition Entry

The single 0xEE partition:
```
Offset  Size  Description
0       1     Status (0x00)
1       3     CHS start (0x000200 or 0x000100)
4       1     Type (0xEE = GPT Protective)
5       3     CHS end (0xFFFFFF)
8       4     LBA start (1)
12      4     LBA count (disk size or 0xFFFFFFFF)
```

## vs Hybrid MBR

| Feature | Protective | Hybrid |
|---------|------------|--------|
| MBR entries | 1 (0xEE) | Multiple real |
| BIOS bootable | No | Yes |
| Purpose | Protection | Compatibility |
| GPT spec | Required | Deviation |

## Detection

1. Valid MBR signature (0xAA55)
2. First partition type is 0xEE
3. Other entries are empty/zero
4. "EFI PART" at LBA 1

## Linux Behavior

Linux recognizes protective MBR and reads GPT instead.
The 0xEE partition is not exposed as a device.

## Tools

Most partitioning tools create protective MBR automatically:
- gdisk, parted, fdisk (GPT mode)
- Windows Disk Management
- macOS Disk Utility

---
title: MBR/DOS
created: 1983
related:
  - format/pt/gpt
  - format/pt/minix
detect:
  - offset: 510
    type: le16
    value: 0xAA55
    name: boot_signature
    then:
      - offset: 0
        type: byte
        op: "!="
        value: 0xEB
        name: not_fat_jump
      - any:
          - offset: 450
            type: byte
            op: "!="
            value: 0
            name: partition_1_type
          - offset: 466
            type: byte
            op: "!="
            value: 0
            name: partition_2_type
          - offset: 482
            type: byte
            op: "!="
            value: 0
            name: partition_3_type
          - offset: 498
            type: byte
            op: "!="
            value: 0
            name: partition_4_type
---

# MBR (Master Boot Record)

The Master Boot Record partitioning scheme was introduced with PC DOS 2.0
in 1983. It remains widely used despite the 2TB disk size limitation.

## Characteristics

- Up to 4 primary partitions
- Extended partitions for more (logical drives)
- Maximum disk size: 2 TB (with 512-byte sectors)
- Boot code in first 446 bytes
- Partition table at offset 446 (64 bytes)
- Signature 0xAA55 at offset 510

## Structure

```
Offset  Size  Description
0       446   Boot code
446     16    Partition entry 1
462     16    Partition entry 2
478     16    Partition entry 3
494     16    Partition entry 4
510     2     Boot signature (0x55 0xAA)
```

## Partition Entry (16 bytes)

```
Offset  Size  Description
0       1     Boot indicator (0x80 = bootable)
1       3     CHS start address
4       1     Partition type
5       3     CHS end address
8       4     LBA start sector
12      4     Number of sectors
```

## Common Partition Types

| Type | Description |
|------|-------------|
| 0x00 | Empty |
| 0x01 | FAT12 |
| 0x04 | FAT16 <32MB |
| 0x05 | Extended |
| 0x06 | FAT16 |
| 0x07 | NTFS/exFAT |
| 0x0B | FAT32 (CHS) |
| 0x0C | FAT32 (LBA) |
| 0x0F | Extended (LBA) |
| 0x82 | Linux swap |
| 0x83 | Linux |
| 0xEE | GPT protective |

## Detection Notes

The 0xAA55 signature alone isn't definitive - many formats use it.
Check for valid partition entries and absence of GPT protective MBR.

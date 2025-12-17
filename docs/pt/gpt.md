---
title: GPT
created: 2000
related:
  - pt/mbr
detect:
  - offset: 512
    type: string
    value: "EFI PART"
    name: gpt_signature
    then:
      - offset: 520
        type: le32
        name: revision
---

# GPT (GUID Partition Table)

GPT was developed as part of the UEFI specification to replace MBR.
It supports disks larger than 2TB and provides redundancy with backup
headers.

## Characteristics

- Up to 128 partitions (typically)
- Maximum disk size: 9.4 ZB (with 512-byte sectors)
- Uses GUIDs for partition identification
- Protective MBR for legacy compatibility
- Backup header at end of disk
- CRC32 checksums for integrity

## Structure

```
LBA 0     Protective MBR
LBA 1     GPT Header
LBA 2-33  Partition entries (128 bytes each)
...       Partitions
LBA -33   Backup partition entries
LBA -1    Backup GPT header
```

## GPT Header (92 bytes)

```
Offset  Size  Description
0       8     Signature "EFI PART"
8       4     Revision (usually 0x00010000)
12      4     Header size (usually 92)
16      4     Header CRC32
20      4     Reserved
24      8     Current LBA
32      8     Backup LBA
40      8     First usable LBA
48      8     Last usable LBA
56      16    Disk GUID
72      8     Partition entries LBA
80      4     Number of entries
84      4     Entry size (usually 128)
88      4     Partition entries CRC32
```

## Partition Entry (128 bytes)

```
Offset  Size  Description
0       16    Partition type GUID
16      16    Unique partition GUID
32      8     First LBA
40      8     Last LBA
48      8     Attributes
56      72    Partition name (UTF-16LE)
```

## Common Type GUIDs

| GUID | Type |
|------|------|
| C12A7328-F81F-11D2-BA4B-00A0C93EC93B | EFI System |
| EBD0A0A2-B9E5-4433-87C0-68B6B72699C7 | Microsoft Basic Data |
| 0FC63DAF-8483-4772-8E79-3D69D8477DE4 | Linux filesystem |
| E6D6D379-F507-44C2-A23C-238F2A3DF928 | Linux LVM |

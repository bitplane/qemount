---
title: QNX4 Partition Table
created: 1990
related:
  - format/fs/qnx4
  - format/fs/qnx6
detect:
  - offset: 510
    type: le16
    value: 0xAA55
    then:
      - offset: 0x1BE
        type: u8
        value: 0x4D
        name: qnx4_type
      - offset: 0x1BE
        type: u8
        value: 0x4E
        name: qnx4_type_alt
      - offset: 0x1BE
        type: u8
        value: 0x4F
        name: qnx4_type_alt2
---

# QNX4 Partition Table

QNX4 partitions are identified by specific type codes within a standard
MBR partition table. Common in embedded and industrial systems.

## Characteristics

- MBR-based partitioning
- Specific partition type codes
- Common in automotive, industrial
- Supports subpartitions

## Partition Types

| Type | Description          |
|------|----------------------|
| 0x4D | QNX4.x               |
| 0x4E | QNX4.x 2nd partition |
| 0x4F | QNX4.x 3rd partition |
| 0x77 | QNX4.x (old)         |
| 0x78 | QNX4.x (old)         |
| 0x79 | QNX4.x (old)         |
| 0xB1 | QNX6                 |
| 0xB2 | QNX6                 |
| 0xB3 | QNX6                 |

## QNX Subpartitions

Within a QNX partition, there can be subpartitions:
- QNX has its own internal partition table
- Allows multiple filesystems within one MBR partition
- Similar concept to BSD slices

## Structure

Standard MBR with QNX type codes, plus internal:

```
QNX Partition Header
├── Subpartition 1
├── Subpartition 2
├── ...
└── Subpartition n
```

## Use Cases

- Automotive (Audi, BMW infotainment)
- Industrial control systems
- Medical devices
- Real-time embedded systems

## Linux Support

Linux kernel recognizes QNX partition types and can parse
QNX4 subpartitions (CONFIG_QNX4FS_FS includes partition support).

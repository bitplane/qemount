---
title: Acorn
created: 1987
related:
  - format/fs/adfs
  - format/fs/filecore
detect:
  - offset: 0x1C0
    type: u8
    value: 0x4C
    name: linux_marker
    then:
      - offset: 0x1C2
        type: le32
        name: start_sector
  - offset: 0xC00
    type: le32
    value: 0x414D5241
    name: arm_magic
---

# Acorn Partition Map

Acorn partition maps are used by RISC OS and older Acorn computers.
Multiple formats exist depending on the specific hardware and OS version.

## Characteristics

- Native to RISC OS / Arthur
- Multiple format variants
- Can coexist with other schemes
- FileCore based systems

## Formats

### ADFS/FileCore

ADFS disks have boot block at start containing disc record.
No explicit partition table - single filesystem per disk.

### Acorn Linux Partition

Linux on Acorn uses a specific signature to identify partitions:

```
Offset   Size  Description
0x1C0    1     Marker (0x4C = 'L' for Linux)
0x1C1    1     Partition number
0x1C2    4     Start sector
0x1C6    4     Sector count
```

### RISC OS Harddisc4

Harddisc4 format uses:
```
Offset   Size  Description
0xC00    4     Magic "ARMA" (0x414D5241)
0xC04    4     Checksum
0xC08    ...   Partition records
```

## Partition Record

```
Offset  Size  Description
0       4     Start sector
4       4     Size in sectors
8       4     Type
12      ...   Name
```

## Types

| Type | Description |
|------|-------------|
| 0    | Empty       |
| 1    | ADFS        |
| 2    | FileCore    |
| 9    | Linux       |

## Linux Support

Linux kernel has Acorn partition support (CONFIG_ACORN_PARTITION_*).
Handles multiple variants including Cumana, EESOX, ICS, and PowerTec.

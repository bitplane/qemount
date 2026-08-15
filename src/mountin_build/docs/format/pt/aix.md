---
title: AIX LVM
created: 1990
priority: -10
detect:
  all:
    - offset: 0xE00
      type: string
      value: "_LVM"
    - offset: 0xE3C
      type: be16
      name: version
      value: 1
---

# AIX Logical Volume Manager

IBM AIX LVM partition format. Uses a volume group with logical volumes
mapped to physical partitions.

## Detection

LVM record at sector 7 (offset 0xE00 = 7 * 512):
- Magic "_LVM" at offset 0
- Version (BE16) at offset 0x3C, must be 1

## Structure

**LVM Record (sector 7)**
```
Offset  Size  Type   Description
0x00    4     str    Magic "_LVM"
0x04    16    -      Reserved
0x14    4     BE32   LVM area length
0x18    4     BE32   VGDA length (sectors)
0x1C    4     BE32   VGDA PSN[0] (primary)
0x20    4     BE32   VGDA PSN[1] (backup)
0x24    10    -      Reserved
0x2E    2     BE16   PP size (log2)
0x30    12    -      Reserved
0x3C    2     BE16   Version (1)
```

**VGDA (Volume Group Descriptor Area)**
```
Offset  Size  Type   Description
0x00    4     BE32   Timestamp seconds
0x04    4     BE32   Timestamp usec
0x08    16    -      Reserved
0x18    2     BE16   Number of LVs
0x1A    2     BE16   Max LVs
0x1C    2     BE16   PP size
0x1E    2     BE16   Number of PVs
0x20    2     BE16   Total VGDAs
0x22    2     BE16   VGDA size
```

**Physical Volume Descriptor (at VGDA + 17 sectors)**
```
Offset  Size  Type   Description
0x00    16    -      Reserved
0x10    2     BE16   PP count
0x12    2     -      Reserved
0x14    4     BE32   PSN of partition 1
0x18    8     -      Reserved
0x20    ...   PPE[]  Physical partition entries (1016 max)
```

**Physical Partition Entry (32 bytes each)**
```
Offset  Size  Type   Description
0x00    2     BE16   LV index (1-based, 0 = free)
0x02    2     -      Reserved
0x04    2     -      Reserved
0x06    2     BE16   LP index within LV
0x08    24    -      Reserved
```

## Partition Layout

Logical volumes are constructed from contiguous runs of physical partitions.
Each PP has a fixed size (2^pp_size bytes). LV names are stored at
VGDA + vgda_len - 33 sectors.

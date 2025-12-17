---
title: Apple APM
created: 1987
related:
  - fs/hfs
  - fs/hfsplus
detect:
  - offset: 0
    type: be16
    value: 0x4552
    name: driver_descriptor_sig
    then:
      - offset: 512
        type: be16
        value: 0x504D
        name: partition_map_sig
---

# APM (Apple Partition Map)

Apple Partition Map was introduced with the Macintosh II in 1987.
It was used on 68k and PowerPC Macs until Intel Macs switched to GPT.

## Characteristics

- Variable number of partitions
- Partition map is self-describing
- Big-endian format
- Used on 68k, PowerPC Macs
- Maximum disk size: 2 TB

## Structure

**Block 0: Driver Descriptor Map**
```
Offset  Size  Description
0       2     Signature (0x4552 = "ER")
2       2     Block size (usually 512)
4       4     Block count
...
```

**Block 1+: Partition Map Entries**
```
Offset  Size  Description
0       2     Signature (0x504D = "PM")
2       2     Reserved
4       4     Map entries count
8       4     Physical block start
12      4     Physical block count
16      32    Partition name
48      32    Partition type
80      4     Logical block start
84      4     Logical block count
88      4     Flags
...
```

## Partition Types

| Type | Description |
|------|-------------|
| Apple_partition_map | The partition map itself |
| Apple_Driver | Device driver |
| Apple_Driver43 | SCSI driver |
| Apple_HFS | HFS filesystem |
| Apple_HFSX | HFS+ or HFSX |
| Apple_Unix_SVR2 | A/UX |
| Apple_Free | Free space |

## Detection Notes

Look for "ER" (0x4552) at offset 0, then "PM" (0x504D) at offset 512.
The partition map includes itself as the first partition entry.

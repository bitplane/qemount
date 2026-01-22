---
title: IBM DASD
created: 1964
priority: -10
detect:
  any:
    # VOL1 in EBCDIC at sector 1 (FBA) or sector 2 (ECKD with 512-byte mapping)
    - offset: 0x200
      type: be32
      value: 0xE5D6D3F1
    - offset: 0x400
      type: be32
      value: 0xE5D6D3F1
    # LNX1 in EBCDIC
    - offset: 0x200
      type: be32
      value: 0xD3D5E7F1
    - offset: 0x400
      type: be32
      value: 0xD3D5E7F1
    # CMS1 in EBCDIC
    - offset: 0x200
      type: be32
      value: 0xC3D4E2F1
    - offset: 0x400
      type: be32
      value: 0xC3D4E2F1
---

# IBM DASD (Direct Access Storage Device)

DASD is the disk format used by IBM mainframes (System/360, z/Architecture).
Uses EBCDIC encoding for all text fields.

## Detection

Label at sector 1 (FBA) or sector 2 (ECKD):
- "VOL1" in EBCDIC = 0xE5D6D3F1
- "LNX1" in EBCDIC = 0xD3D5E7F1
- "CMS1" in EBCDIC = 0xC3D4E2F1

Label location depends on device type and block size:
- ECKD: block 2 (sector 2 with 512-byte blocks)
- FBA: block 1 (sector 1)
- CMS on FBA with DIAG: sector 1 regardless of block size

## Label Types

| Type | EBCDIC     | Description |
|------|------------|-------------|
| VOL1 | 0xE5D6D3F1 | IBM standard CDL (Compatible Disk Layout) |
| LNX1 | 0xD3D5E7F1 | Linux LDL (Linux Disk Layout) |
| CMS1 | 0xC3D4E2F1 | VM/CMS formatted minidisk |

## Structure

**VOL1 Label (CDL)**
```
Offset  Size  Type    Description
0x00    4     EBCDIC  Label ID "VOL1"
0x04    1     u8      Label number
0x05    6     EBCDIC  Volume serial (volid)
0x0B    1     u8      Security
0x0C    5     EBCDIC  Reserved
0x11    10    EBCDIC  Padding
0x1B    5     EBCDIC  CCHH of VTOC extent
0x20    21    EBCDIC  Reserved
0x35    14    EBCDIC  Owner
0x43    29    EBCDIC  Reserved
```

**LNX1 Label (LDL)**
```
Offset  Size  Type    Description
0x00    4     EBCDIC  Label ID "LNX1"
0x04    6     EBCDIC  Volume serial (volid)
0x0A    1     u8      Version (0xF2 = large volume support)
0x0B    8     u64     Formatted blocks
...
```

**CMS1 Label**
```
Offset  Size  Type    Description
0x00    4     EBCDIC  Label ID "CMS1"
0x04    6     EBCDIC  Volume serial (volid)
0x0A    2     BE16    Version
0x0C    4     BE32    Block size
0x10    4     BE32    Disk offset (for minidisks)
0x14    4     BE32    Block count
...
```

## VTOC (VOL1 only)

VOL1 labels point to a VTOC (Volume Table of Contents) containing
Format 1 (FMT1) and Format 8 (FMT8) labels for each partition.

**VTOC Location**: Stored as CCHH in VOL1 label, converted to block number.

**FMT1/FMT8 Dataset Labels**:
- FMT1: Standard dataset extent
- FMT4: VTOC descriptor (skip)
- FMT5: Free space (skip)
- FMT7: Extension (skip)
- FMT8: Large dataset extent
- FMT9: Extension (skip)

## Partition Layout

| Type | Partitions |
|------|------------|
| VOL1 | Multiple, from VTOC FMT1/FMT8 labels |
| LNX1 | Single, starts after label block |
| CMS1 | Single, offset/size from label |

## Device Types

**ECKD (Count-Key-Data)**
- Traditional mainframe format
- Tracks and cylinders geometry
- Variable-length records
- Devices: 3390, 3380, 9345

**FBA (Fixed Block Architecture)**
- Fixed 512-byte blocks
- Linear addressing
- Devices: 9336, SCSI, virtio

## Linux Support

Linux on IBM Z (s390x) supports DASD natively via the dasd driver.
Requires s390x hardware or z/VM virtualization.

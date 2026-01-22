---
title: IBM DASD
created: 1964
related: []
detect:
  - offset: 0
    type: string
    value: "VOL1"
    name: volume_label
---

# IBM DASD (Direct Access Storage Device)

DASD is the disk format used by IBM mainframes (System/360, z/Architecture).
It represents a fundamentally different disk abstraction from PC-style
partitioning.

## Characteristics

- EBCDIC character encoding
- CKD (Count-Key-Data) or FBA (Fixed Block Architecture)
- Record-oriented, not byte-stream
- Volume labels and VTOC
- Used on z/OS, z/VM, z/Linux

## Format Types

### CKD (Count-Key-Data)
Traditional mainframe format:
- Variable-length records
- Tracks and cylinders
- Hardware-assisted record access

### FBA (Fixed Block Architecture)
More modern format:
- Fixed 512-byte blocks
- Simpler addressing
- Used in virtualized environments

## Structure

**Volume Label (VOL1)**
```
Offset  Size  Description
0       4     Label ID "VOL1"
4       6     Volume serial number
10      1     Security byte
11      ...   Owner
```

**VTOC (Volume Table of Contents)**
Contains dataset (file) allocation information.

## Formats

| Type | Description             |
|------|-------------------------|
| LDL  | Linux disk layout       |
| CDL  | Compatible disk layout  |
| CMS  | CMS-formatted minidisks |

## Linux Support

Linux on IBM Z (s390x) supports DASD natively.
Not usable on x86/ARM platforms - requires mainframe
hardware or z/VM virtualization.

## QEMU Notes

QEMU can emulate s390x but DASD support requires
special configuration. Typical x86 QEMU cannot use
DASD images directly.

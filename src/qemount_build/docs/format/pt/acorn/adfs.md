---
title: Acorn ADFS
created: 1987
priority: -10
related:
  - format/fs/adfs
detect:
  all:
    - offset: 0xDC1
      type: byte
      name: secspertrack
      op: ">"
      value: 0
      then:
        - offset: 0xDC1
          type: byte
          op: "<"
          value: 64
    - offset: 0xDC2
      type: byte
      name: heads
      op: ">"
      value: 0
    - any:
        - offset: 0xDD0
          type: le32
          name: disc_size
          op: ">"
          value: 0
        - offset: 0xDF4
          type: le32
          name: disc_size_high
          op: ">"
          value: 0
---

# Acorn ADFS Partition Table

Native Acorn Advanced Disc Filing System partition format.
Boot block at sector 6 contains disc record with geometry and size.

## Detection

Sector 6 (offset 0xC00 = 6 * 512) contains:
- Disc record at offset 0x1c0 within sector (0xC00 + 0x1c0 = 0xDC0)
- But we check at sector start for simplicity

Note: Full validation requires boot block checksum which is computed at runtime.
This detection uses heuristics (reasonable geometry values).

## Structure

**Boot Block (sector 6)**
```
Offset  Size  Description
0x1c0   60    Disc record
```

**Disc Record**
```
Offset  Size  Description
0       1     log2secsize
1       1     secspertrack (must be 1-63)
2       1     heads (must be 1-255)
8       1     lowsector
16      4     disc_size (LE32)
36      4     disc_size_high (LE32)
```

## Partition Layout

- Primary: ADFS partition (size from disc record)
- Secondary: Optional, identified by byte 0x1fc:
  - 1 = RISCiX MFM
  - 2 = RISCiX SCSI
  - 9 = Linux

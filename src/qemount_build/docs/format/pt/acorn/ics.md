---
title: Acorn ICS
created: 1990
priority: -10
related:
  - format/pt/acorn/adfs
detect:
  - offset: 0
    type: checksum
    length: 512
    algorithm: ics
---

# Acorn ICS Partition Table

Integrated Computer Solutions SCSI partition format for Acorn RISC OS.

## Detection

ICS checksum validation at sector 0:
- `sum(bytes[0..507]) + 0x50617274 == le32(bytes[508..511])`
- 0x50617274 is "Part" in ASCII

## Structure

**Partition Entry (sector 0)**
```
Offset  Size  Description
0       ?     Partition data
508     4     Checksum (LE32)
```

## Partition Layout

Up to 8 partitions defined in sector 0.

---
title: Acorn PowerTec
created: 1992
priority: -10
related:
  - format/pt/acorn/adfs
detect:
  - offset: 0
    type: checksum
    length: 512
    algorithm: powertec
---

# Acorn PowerTec Partition Table

PowerTec SCSI partition format for Acorn RISC OS.

## Detection

PowerTec checksum validation at sector 0:
- `sum(bytes[0..510]) + 0x2a == byte[511]`
- Rejects disks with MBR signature (0x55AA at 510-511)

## Structure

**Partition Entry (sector 0)**
```
Offset  Size  Description
0       511   Partition data
511     1     Checksum byte
```

## Partition Layout

Up to 8 partitions defined in sector 0.

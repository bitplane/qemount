---
title: AIX
created: 1986
related:
  - format/pt/mbr
detect:
  - offset: 0
    type: be32
    value: 0xC9C2D4C1
    name: aix_magic
---

# AIX Partition Table

IBM AIX uses a specific disk label format for physical volumes,
distinct from its Logical Volume Manager (LVM) layer.

## Characteristics

- Big-endian format
- Physical volume identification
- Magic number 0xC9C2D4C1 ("IBMA" in EBCDIC-ish)
- Used on RS/6000 and pSeries

## Structure

**Physical Volume Header**
```
Offset  Size  Description
0       4     Magic (0xC9C2D4C1)
4       ...   PV identifier
...
```

## AIX vs AIX LVM

AIX has two layers:

1. **Physical Volume (PV)**: Raw disk identification
2. **Logical Volume Manager**: Volume groups, logical volumes

The partition detection in Linux identifies AIX physical volumes,
but full LVM support requires additional handling.

## Use Cases

- IBM RS/6000 workstations
- IBM pSeries servers
- AIX operating system disks
- POWER architecture systems

## Linux Support

Linux kernel can detect AIX disk labels (CONFIG_AIX_PARTITION).
This identifies the disk as AIX-formatted but doesn't provide
full LVM volume access.

## Historical Note

AIX was one of the first Unix systems with an integrated LVM,
influencing later implementations like HP-UX LVM and Linux LVM2.

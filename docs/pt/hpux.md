---
title: HP-UX LIF/VTOC
type: pt
created: 1984
related:
  - pt/sun
  - pt/gpt
detect:
  - offset: 0
    type: be16
    value: 0x8000
    name: lif_magic
---

# HP-UX Disklabel (LIF/VTOC)

HP-UX uses a combination of LIF (Logical Interchange Format) and VTOC
(Volume Table of Contents) for disk partitioning on PA-RISC and older
Itanium systems.

## Characteristics

- Big-endian format
- LIF header at start of disk
- VTOC embedded within LIF
- Used on PA-RISC, early Itanium
- Modern HP-UX on Itanium uses GPT

## LIF (Logical Interchange Format)

Originally a tape format, adapted for disk boot:

```
Offset  Size  Description
0       2     Magic (0x8000)
2       6     Volume label
8       4     Directory start
12      2     System 3000 flag
14      2     Dummy
16      4     Directory length
...
```

## VTOC Structure

Embedded within LIF directory:

```
Offset  Size  Description
0       4     Sanity (0x0E10C407)
4       4     Version
8       ...   Partition entries
```

## Partition Entry

```
Offset  Size  Description
0       4     Start sector
4       4     Size in sectors
8       4     Type
12      4     Flags
```

## Platforms

- **HP 9000**: PA-RISC workstations/servers
- **HP Integrity**: Early Itanium (pre-GPT)
- **HP-UX 11i v3+**: Moved to GPT on Itanium

## Linux Support

Linux has basic HP-UX partition support. The LIF format is
primarily used for boot, with VTOC describing actual partitions.

## Historical Note

LIF was originally designed for HP's tape interchange format
in the 1980s, then adapted for disk booting on HP 9000 series.

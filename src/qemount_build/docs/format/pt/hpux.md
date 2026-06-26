---
title: HP-UX LIF/VTOC
created: 1984
related:
  - format/pt/sun
  - format/pt/gpt
  - format/fs/hp-lif
  - format/fs/cpm
# No detect rule. The 0x8000 word at offset 0 is the generic LIF system word
# (an HP-UX boot area is itself a LIF volume), so detecting on it alone wrongly
# claimed every plain LIF volume as an HP-UX disk. The 0x8000 marker now resolves
# to format/fs/hp-lif. Recovering HP-UX-specific partitioning needs the VTOC
# sanity (0x0E10C407) at its on-disk offset, which no available reference tool
# (file, disktype) pins down — see the deferred queue.
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

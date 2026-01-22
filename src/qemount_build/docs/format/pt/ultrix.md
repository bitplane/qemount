---
title: Ultrix
created: 1984
priority: -10
detect:
  all:
    - offset: 0x3FB8
      type: le32
      value: 0x032957
    - offset: 0x3FBC
      type: le32
      value: 1
---

# Ultrix Partition Table

DEC Ultrix disklabel format, used on VAX and MIPS DECstation systems.

## Detection

Disklabel at offset 16312 (0x3FB8 = 16384 - 72):
- Magic 0x032957 (LE32) at offset 0
- Valid flag 1 (LE32) at offset 4

## Structure

**Disklabel (72 bytes at offset 16312)**
```
Offset  Size  Type   Description
0x00    4     LE32   Magic (0x032957)
0x04    4     LE32   Valid flag (1)
0x08    64    entry  Partition table (8 entries)
```

**Partition Entry (8 bytes)**
```
Offset  Size  Type   Description
0x00    4     LE32   Size in sectors (pi_nblocks)
0x04    4     LE32   Start sector (pi_blkoff)
```

## Partitions

Up to 8 partitions. Valid if nblocks > 0.

## Historical Note

Ultrix was DEC's Unix variant, running on:
- VAX (1984-1995)
- MIPS DECstation (1989-1995)

Replaced by Digital Unix (later Tru64) on Alpha.

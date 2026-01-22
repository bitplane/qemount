---
title: SYSV68
created: 1985
priority: -10
detect:
  - offset: 0xF8
    type: string
    value: "MOTOROLA"
---

# SYSV68 (Motorola 68k System V)

SYSV68 is the partitioning scheme used by System V Unix on
Motorola 68000-series workstations.

## Detection

"MOTOROLA" string at offset 248 (0xF8).

## Structure

**Block 0 (512 bytes)**
```
Offset  Size  Type   Description
--- Volume ID (first 256 bytes) ---
0x00    248   -      Unused
0xF8    8     str    Magic "MOTOROLA"
--- DK Config (second 256 bytes) ---
0x100   128   -      Unused
0x180   4     BE32   Slice table sector (ios_slcblk)
0x184   2     BE16   Slice count (ios_slccnt)
0x186   122   -      Unused
```

**Slice Table (at sector ios_slcblk)**
```
Offset  Size  Type   Description
0x00    4     BE32   Size in blocks (nblocks)
0x04    4     BE32   Block offset (blkoff)
```

Each slice entry is 8 bytes. Last slice is whole disk (skipped).

## Platforms

- **Motorola MVME**: VMEbus computers
- **Integrated Solutions**: Various 68k systems

## Historical Note

The 68k architecture was popular for Unix workstations
in the 1980s before RISC processors took over.

---
title: Sun VTOC8/VTOC16
created: 1983
related:
  - pt/sun
detect:
  - offset: 508
    type: be16
    value: 0xDABE
    name: vtoc_sanity
---

# Sun VTOC Variants (VTOC8/VTOC16)

Sun's VTOC (Volume Table of Contents) has variants based on partition
count and platform (SPARC vs x86).

## Variants

### VTOC8 (Traditional SPARC)
- 8 partitions (slices 0-7)
- Big-endian
- Original Sun format
- Magic 0xDABE at offset 508

### VTOC16 (x86 Solaris)
- 16 partitions
- Little-endian on x86
- Extended format for Solaris x86
- Can coexist with MBR/GPT

## SPARC vs x86

| Feature | SPARC | x86 |
|---------|-------|-----|
| Endian | Big | Little |
| Partitions | 8 | 16 |
| Boot | Direct from VTOC | MBR then VTOC |
| Location | Sector 0 | Inside partition |

## Structure

VTOC8 and VTOC16 share basic structure but differ in:
- Partition entry count
- Byte ordering
- Location on disk

## x86 Solaris Layout

On x86, VTOC is inside an MBR partition:
```
MBR
└── Solaris2 partition (type 0xBF)
    └── VTOC (at start of partition)
        └── Slices s0-s15
```

## EFI/GPT Era

Modern Solaris/illumos prefers GPT (EFI label) over VTOC:
- SMI label: Traditional VTOC
- EFI label: GPT-based

## Linux Support

Linux kernel parses both VTOC8 and VTOC16 formats
(CONFIG_SUN_PARTITION). Auto-detects based on disk.

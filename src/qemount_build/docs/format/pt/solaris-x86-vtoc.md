---
title: Solaris x86 VTOC16
created: 1992
related:
  - format/pt/mbr
  - format/pt/sun-sparc
  - format/fs/ufs1
detect:
  - offset: 524
    type: le32
    value: 0x600DDEEE
    name: vtoc_sanity
  - offset: 542
    type: le16
    value: 16
    name: slice_count
  - offset: 1020
    type: le16
    value: 0xDABE
    name: label_magic
---

# Solaris x86 VTOC16

Solaris on x86 traditionally places a little-endian VTOC16 disk label inside
an MBR partition of type `0x82` (Solaris) or `0xBF` (Solaris2). The label is at
sector 1 relative to that enclosing partition and describes up to 16 slices.

This is distinct from the big-endian VTOC8 disklabel used on SPARC systems.

## Structure

The label occupies one 512-byte sector at relative LBA 1. Its embedded VTOC
starts at the beginning of that sector.

| Label offset | Size | Description |
|-------------:|-----:|-------------|
| 12           | 4    | Sanity value (`0x600DDEEE`, little-endian) |
| 16           | 4    | Version |
| 28           | 2    | Sector size |
| 30           | 2    | Number of slices (16) |
| 72           | 192  | 16 slice entries, 12 bytes each |
| 508          | 2    | Label magic (`0xDABE`, little-endian) |
| 510          | 2    | XOR checksum |

Each slice entry contains a 16-bit tag, a 16-bit flag field, a 32-bit starting
sector and a signed 32-bit sector count. Slice 2 conventionally describes the
whole enclosing Solaris partition and is not exposed as a child filesystem.

Slice offsets are relative to the enclosing MBR partition.


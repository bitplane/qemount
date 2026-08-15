---
title: Filecore
created: 1987
related:
  - format/fs/adfs
---

# Filecore

Filecore is the low-level disc handling module used by RISC OS on Acorn
and later ARM-based computers. ADFS and other RISC OS filesystems are
built on top of Filecore.

## Characteristics

- Zone-based disc organization
- Map with checksums for integrity
- Fragment ID based allocation
- Supports multiple filesystem types
- Flexible block sizes

## Structure

### Hard Disc Images

Boot block is 512 bytes at disc address 0xC00 (3072 bytes from start).
The disc record (60 bytes, little-endian) sits at offset 0x1C0 within the
boot block, giving absolute offset 0xDC0.

A checksum byte at offset 0xDFF (byte 511 of boot block) is an 8-bit
add-with-carry of the preceding 511 bytes.

### Floppy Images

No boot block. Root directory starts early in the image with a 4-byte
ASCII validation string:

| Signature | Format | Typical offset |
|-----------|--------|----------------|
| `Hugo`    | Old directory (L format) | 0x200 |
| `Nick`    | New directory (D/E/F)    | 0x200 or 0x400 |
| `SBPr`    | Big directory (E+/F+)    | At root dir start |

### General

- Zone maps track allocation
- Fragment IDs track file extents
- Directory structure varies by format
- Root directory at known location

## Formats Using Filecore

| Format  | Description             |
|---------|-------------------------|
| ADFS    | Main Acorn filesystem   |
| DOSFS   | FAT access via Filecore |
| CDFS    | CD-ROM access           |
| Various | Third-party formats     |

## Zone Map

- Disc divided into zones
- Each zone has allocation bitmap
- Fragment IDs track file extents
- Cross-check bits for validation

## Detection

FileCore has no magic number. Detection uses structural validation:

**Hard disc images**: Validate the boot block checksum at offset 0xDFF
(8-bit add-with-carry of 511 preceding bytes at 0xC00-0xDFE), then check
the disc record at 0xDC0: `log2secsize` (byte 0) must be 8, 9, or 10.

**Floppy images**: Check for ASCII string `Hugo` at offset 0x200 (old
directory format) or `Nick` at 0x200/0x400 (new directory format).

Neither `file(1)` nor `libblkid` have FileCore detection. The Linux kernel
ADFS driver (`fs/adfs/super.c`) validates via boot block checksum +
disc record plausibility.

## Linux/NetBSD Support

- NetBSD has native Filecore support
- Linux accesses via ADFS driver
- Read-only or limited write support

## Historical Note

Filecore was designed to be modular, allowing different filing systems
to share common disc handling code. This was innovative for its time
and allowed RISC OS to support multiple formats efficiently.

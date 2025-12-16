---
title: Filecore
type: fs
created: 1987
related:
  - fs/adfs
detect:
  # Detection via disc record structure at sector 0
  # Zone-based map with checksums
  # No simple magic number - validated by structure
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

- Boot block at sector 0
- Disc record contains format info
- Zone maps track allocation
- Directory structure varies by format
- Root directory at known location

## Formats Using Filecore

| Format | Description |
|--------|-------------|
| ADFS | Main Acorn filesystem |
| DOSFS | FAT access via Filecore |
| CDFS | CD-ROM access |
| Various | Third-party formats |

## Zone Map

- Disc divided into zones
- Each zone has allocation bitmap
- Fragment IDs track file extents
- Cross-check bits for validation

## Linux/NetBSD Support

- NetBSD has native Filecore support
- Linux accesses via ADFS driver
- Read-only or limited write support

## Historical Note

Filecore was designed to be modular, allowing different filing systems
to share common disc handling code. This was innovative for its time
and allowed RISC OS to support multiple formats efficiently.

---
title: RomFS
created: 1997
related:
  - format/fs/cramfs
  - format/fs/squashfs
detect:
  - type: string
    value: "-rom1fs-"
    then:
      - offset: 8
        type: be32
        name: size
      - offset: 16
        type: string
        name: volume_name
---

# RomFS

RomFS is a simple read-only filesystem for Linux, designed for minimal
overhead in embedded systems. Created by Janos Farkas in 1997, it's one of
the simplest Linux filesystems.

## Characteristics

- Read-only
- No compression
- Minimal overhead (~32 bytes per file)
- Maximum volume size: 4 GB (32-bit size field)
- Big-endian metadata
- Sequential file layout
- No timestamps or permissions (beyond execute bit)

## Structure

- Superblock at offset 0 (no boot sector reservation)
- Magic string "-rom1fs-" (8 bytes)
- Full size at offset 8 (big-endian 32-bit)
- Checksum at offset 12
- Volume name at offset 16 (null-terminated, 16-byte aligned)
- File headers follow immediately

## File Header Format

| Offset | Size | Field |
|--------|------|-------|
| 0 | 4 | Next file header (aligned) + type nibble |
| 4 | 4 | Spec.info (hardlink/device/size) |
| 8 | 4 | Size (for regular files) |
| 12 | 4 | Checksum |
| 16 | var | Filename (null-terminated, padded to 16 bytes) |
| - | var | File data (padded to 16 bytes) |

## File Types

| Type | Value | Description |
|------|-------|-------------|
| 0 | hardlink | Link to another file |
| 1 | directory | Contains file entries |
| 2 | regular | Normal file |
| 3 | symlink | Symbolic link |
| 4 | block dev | Block device |
| 5 | char dev | Character device |
| 6 | socket | Unix socket |
| 7 | fifo | Named pipe |

## Use Cases

- Embedded system firmware
- Initial ramdisk (initrd) - historically
- Boot ROMs
- Minimal root filesystems
- Anywhere CramFS/SquashFS is overkill

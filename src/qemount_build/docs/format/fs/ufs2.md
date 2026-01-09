---
title: UFS2
created: 2002
related:
  - format/fs/ufs1
  - format/fs/zfs
detect:
  any:
    - offset: 0xa54c
      type: le32
      value: 0x19540119
    - offset: 0xa54c
      type: be32
      value: 0x19540119
    - offset: 0x1054c
      type: le32
      value: 0x19540119
    - offset: 0x1054c
      type: be32
      value: 0x19540119
---

# UFS2 (Unix File System Version 2)

UFS2 was developed by Kirk McKusick for FreeBSD 5.0 (2002) as a major update
to UFS1. It added 64-bit support, extended attributes, and is the default
filesystem for FreeBSD.

## Characteristics

- 64-bit block pointers
- Maximum file size: 8 ZB (zettabytes)
- Maximum volume size: 8 ZB
- Extended attributes
- Native ACL support
- Block sizes: 4096 to 65536 bytes
- Soft updates + journaling (SUJ)
- Snapshots

## Structure

- Boot block at offset 0
- Superblock at offset 65536 (64K) or higher
- Magic 0x19540119 at offset 0xa54c or 0x1054c
- Cylinder groups with local metadata
- Extended inode format (256 bytes)
- Attribute blocks for extended attributes

## Key Improvements over UFS1

| Feature | UFS1 | UFS2 |
|---------|------|------|
| Block addresses | 32-bit | 64-bit |
| Max file size | 4 GB | 8 ZB |
| Inode size | 128 bytes | 256 bytes |
| Extended attrs | No | Yes |
| Snapshots | No | Yes |
| Timestamps | Second | Nanosecond |

## Soft Updates Journaling (SUJ)

FreeBSD 9.0+ added journaling to soft updates:
- Fast crash recovery (no full fsck)
- Intent log for metadata
- Compatible with snapshots

## Magic Number

The magic 0x19540119 is the same date as UFS1's magic (0x00011954) in a
different format: 1954-01-19 - the birthday of Marshall Kirk McKusick.

## Linux Support

Linux UFS support is limited:
- Read-only recommended
- Write support experimental
- FreeBSD UFS2 most compatible

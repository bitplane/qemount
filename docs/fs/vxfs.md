---
title: VxFS
type: fs
created: 1991
related:
  - fs/ext4
  - fs/xfs
detect:
  - offset: 0x2000
    type: le32
    value: 0xa501fcf5
---

# VxFS (Veritas File System)

VxFS was developed by Veritas Software (now part of Broadcom) starting in
1991. It's an extent-based journaling filesystem designed for enterprise
use, often bundled with Veritas Volume Manager (VxVM).

## Characteristics

- Extent-based allocation
- Intent logging (journaling)
- Online administration
- Maximum file size: 256 TB
- Maximum volume size: 256 TB
- Dynamic inode allocation
- Multi-volume support

## Structure

- Superblock at offset 8192 (8KB)
- Magic 0xA501FCF5 in superblock
- Backup superblocks at various offsets
- Object Location Table (OLT)
- Intent log for journaling

## Key Features

- **Online Resize**: Grow/shrink while mounted
- **Snapshots**: Point-in-time copies
- **Quick I/O**: Direct I/O for databases
- **Data Change Log**: Track file changes
- **Storage Checkpoints**: Instant backups

## Disk Layout Versions

| Version | Features |
|---------|----------|
| 6 | Basic VxFS |
| 7 | Large file support |
| 8 | Extended features |
| 9-12 | Modern enhancements |

## Platforms

- Solaris, HP-UX, AIX
- Linux (commercial license)
- Windows (limited)

## Linux Support

Linux has read-only VxFS support for disk layout versions 2, 3, and 4.
Newer versions require Veritas commercial drivers.

---
title: UFS1
created: 1983
discontinued: 2003
related:
  - format/fs/ufs2
  - format/fs/ext2
detect:
  any:
    - offset: 0x255c
      type: le32
      value: 0x00011954
    - offset: 0x255c
      type: be32
      value: 0x00011954
---

# UFS1 (Unix File System Version 1)

UFS1, also known as FFS (Fast File System), was developed at UC Berkeley for
4.2BSD in 1983 by Marshall Kirk McKusick. It was a major advancement over the
original Unix filesystem, introducing cylinder groups and improved block
allocation.

## Characteristics

- Cylinder group organization
- 32-bit block addresses
- Maximum file size: 4 GB (32-bit)
- Block sizes: 4096 to 65536 bytes
- Fragment sizes: 512 to 8192 bytes
- Soft updates (optional, for consistency)
- No journaling (original)

## Structure

- Boot block at offset 0
- Superblock at offset 8192 (may vary)
- Magic 0x00011954 at offset 9564 (within superblock)
- Cylinder groups with local metadata
- Inodes and data blocks per cylinder group
- Backup superblocks in each cylinder group

## BSD Variants

| OS | Notes |
|----|-------|
| 4.2BSD | Original FFS |
| SunOS/Solaris | Logging UFS |
| FreeBSD | Soft updates |
| NetBSD | WAPBL journaling (optional) |
| OpenBSD | Softdep |
| MirOS BSD | OpenBSD fork |

## MBR Partition Types

BSD systems use their own partition types, but the filesystem is detected
by the UFS magic number regardless:

| Type | OS |
|------|----|
| 0x27 | MirOS BSD |
| 0xA5 | FreeBSD |
| 0xA6 | OpenBSD |
| 0xA9 | NetBSD |

Note: BSD systems typically use a disklabel inside the partition for
further subdivision, so the MBR partition contains a BSD disklabel
which then contains the actual UFS filesystem(s).

## Magic Number

The magic 0x00011954 represents January 19, 1954 - the birthday of Marshall
Kirk McKusick, the primary developer of FFS/UFS.

## Linux Support

Linux has limited UFS support:
- Read-only for most variants
- Some write support for UFS1
- Often read-only due to variant complexity

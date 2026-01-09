---
title: EFS
created: 1988
discontinued: 1994
related:
  - format/fs/xfs
detect:
  - offset: 0x200
    type: be32
    value: 0x00072959
---

# EFS (Extent File System)

EFS was developed by Silicon Graphics for IRIX, introduced around 1988.
It was the default IRIX filesystem before XFS and used extent-based
allocation for efficient large file handling.

## Characteristics

- Extent-based allocation
- 32-bit block addresses
- Maximum file size: 8 GB
- Maximum volume size: 8 GB
- Up to 12 extents per inode
- Variable extent length (1-248 blocks)

## Structure

- Boot block at block 0 (unused by EFS)
- Superblock at block 1 (offset 512)
- Magic 0x00072959 in superblock
- Bitmap blocks follow superblock
- Inodes and data blocks
- Backup superblock at last block

## Limitations

- Small maximum sizes (8 GB)
- Limited number of extents per inode
- No journaling
- No ACLs or extended attributes

## Comparison with XFS

| Feature | EFS | XFS |
|---------|-----|-----|
| Max file | 8 GB | 8 EB |
| Max volume | 8 GB | 8 EB |
| Journaling | No | Yes |
| Allocation | Extents | Extents |

## Current Status

- Obsolete - replaced by XFS
- Linux has read-only support
- Useful for accessing old IRIX systems
- SGI stopped IRIX development in 2006

---
title: HPFS
created: 1989
discontinued: 2005
related:
  - format/fs/ntfs
  - format/fs/fat16
detect:
  - offset: 0x2000
    type: le32
    value: 0xf995e849
---

# HPFS (High Performance File System)

HPFS was developed by Microsoft and IBM for OS/2 1.2, released in 1989.
It was designed to overcome FAT limitations and provide better performance
for the OS/2 operating system.

## Characteristics

- B-tree directory structure
- 254 character filenames
- Extended attributes
- Maximum file size: 2 GB
- Maximum volume size: 64 GB (practical: 512 GB)
- Contiguous file allocation
- Case-preserving, case-insensitive

## Structure

- Boot sector at sector 0
- Superblock at sector 16 (offset 8192)
- Magic 0xF995E849 in superblock
- Spare block at sector 17
- Bitmap bands for allocation
- FNodes for file metadata

## Key Innovations

- **FNodes**: Combined inode and extent info
- **B+ Trees**: Fast directory lookups
- **Extended Attributes**: Arbitrary metadata
- **Bands**: Allocation regions to reduce fragmentation

## Comparison with FAT

| Feature       | HPFS      | FAT16  |
|---------------|-----------|--------|
| Filenames     | 254 chars | 8.3    |
| Max file      | 2 GB      | 2 GB   |
| Directories   | B-tree    | Linear |
| Fragmentation | Minimal   | Common |

## Current Status

- OS/2 and eComStation
- Linux has read-only support
- Windows NT 3.x supported it
- Dropped from Windows NT 4.0+

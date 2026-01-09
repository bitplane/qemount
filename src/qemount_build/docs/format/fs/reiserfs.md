---
title: ReiserFS
created: 2001
discontinued: 2006
related:
  - format/fs/ext3
  - format/fs/btrfs
detect:
  any:
    - offset: 0x10034
      type: string
      value: "ReIsErFs"
    - offset: 0x10034
      type: string
      value: "ReIsEr2Fs"
    - offset: 0x10034
      type: string
      value: "ReIsEr3Fs"
    - offset: 0x10000
      type: string
      value: "ReIsEr4"
---

# ReiserFS (Reiser File System v3)

ReiserFS was developed by Hans Reiser and Namesys, released in 2001. It was
the first journaling filesystem included in the mainline Linux kernel (2.4.1)
and was notable for its efficient handling of small files.

Work ceased on it in 2006 when Hans was convicted of murdering his wife.
Reiser4 was maintained as a series of out-of-tree patches but never made it
into mainline Linux. ReiserFS v3 was removed from Linux in 6.13 (2024).

## Characteristics

- Metadata journaling
- B+ tree for all metadata (not just directories)
- Tail packing (small file optimization)
- Maximum file size: 8 TB (v3.6)
- Maximum volume size: 16 TB
- Dynamic inode allocation
- Efficient small file storage

## Structure

- Superblock at offset 65536 (0x10000)
- Magic string at offset 0x10034:
  - "ReIsErFs" (v3.5)
  - "ReIsEr2Fs" (v3.6)
  - "ReIsEr3Fs" (v3.6.19+)
- Single B+ tree for entire filesystem
- Journal at fixed location

## Key Innovations

- **Balanced Tree**: All operations O(log n)
- **Tail Packing**: Small files stored in B+ tree nodes
- **Dynamic Inodes**: No fixed inode count
- **Efficient Directories**: Fast even with millions of files

## Version History

| Version | Magic | Features |
|---------|-------|----------|
| 3.5 | ReIsErFs | Original |
| 3.6 | ReIsEr2Fs | Large file support |
| 3.6.19 | ReIsEr3Fs | Extended attributes |

## Current Status

- **Deprecated**: Removed from Linux 6.13 (2024)
- No longer maintained
- Users advised to migrate to ext4 or btrfs
- Still accessible via older kernels (2.6.x)

## Legacy

ReiserFS influenced later filesystems with its tree-based approach.
Reiser4 was developed as successor but never merged into mainline Linux.

---
title: ext4
type: fs
created: 2008
related:
  - fs/ext2
  - fs/ext3
  - fs/xfs
detect:
  - offset: 0x438
    type: le16
    value: 0xef53
    then:
      - offset: 0x45c
        type: le32
        mask: 0x4
        op: "&"
        value: 0x4
      - offset: 0x460
        type: le32
        op: ">="
        value: 0x40
---

# Fourth Extended Filesystem (ext4)

ext4 was developed as an extension of ext3 and became stable in Linux 2.6.28
(2008). It is the default filesystem for most Linux distributions and offers
significant improvements in performance, scalability, and reliability.

## Characteristics

- Extents (replaces block mapping for large files)
- 48-bit block addressing (up to 1 exbibyte filesystem)
- Maximum file size: 16 TiB
- Maximum filesystem size: 1 EiB
- Nanosecond timestamps
- Journal checksumming
- Multiblock allocation
- Delayed allocation (improves performance)
- Fast fsck (uninitialised block groups)

## Structure

- Superblock at offset 1024 (0x400)
- Magic number 0xef53 at offset 0x438
- 128-byte or 256-byte inodes (ext2/3 used 128)
- Extent tree for file block mapping
- Flex block groups (grouped block groups for performance)

## Key Features Over ext3

- **Extents**: Single descriptor for contiguous blocks vs. indirect block lists
- **64-bit**: Supports filesystems > 16TiB
- **Persistent preallocation**: Reserve space without writing zeros
- **Online defragmentation**: e4defrag tool
- **Metadata checksumming**: Detect corruption

## Detection

Distinguished from ext3 by having larger INCOMPAT feature flags (>= 0x40),
indicating features like extents (0x40), 64-bit (0x80), or flex_bg (0x200).

## Compatibility

Can mount ext2/ext3 filesystems. An ext4 filesystem without extents can
sometimes be mounted as ext3 (not recommended).

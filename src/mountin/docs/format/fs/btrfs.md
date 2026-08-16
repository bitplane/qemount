---
title: Btrfs
created: 2007
related:
  - format/fs/bcachefs
  - format/fs/zfs
  - format/fs/ext4
detect:
  - offset: 0x10040
    type: string
    value: "_BHRfS_M"
---

# B-tree Filesystem (Btrfs)

Btrfs (pronounced "butter FS" or "better FS") is a copy-on-write filesystem for
Linux developed by Chris Mason at Oracle starting in 2007. It was merged into
the Linux kernel in 2009 and declared stable for most features.

## Characteristics

- Copy-on-write (CoW) for data and metadata
- Built-in checksumming (CRC32c, xxhash, sha256, blake2)
- Snapshots and clones (instant, space-efficient)
- Built-in compression (lzo, zlib, zstd)
- Integrated volume management (multiple devices)
- RAID 0, 1, 10, 5, 6 (5/6 still experimental)
- Online defragmentation and resize
- Subvolumes (separate internal filesystems)
- Send/receive for incremental backups

## Structure

- Superblock at offset 0x10000 (64KB), magic at +0x40
- Magic string: "_BHRfS_M" (8 bytes)
- Multiple superblock copies at fixed locations
- Everything stored in B-trees (filesystem tree, extent tree, etc.)
- Extent-based allocation

## Design Principles

- Self-healing with checksums + redundancy
- Efficient snapshots via CoW
- Flexible storage pooling
- Online administration
- Backward and forward compatibility via feature flags

## Known Limitations

- RAID 5/6 write hole (improved but still experimental)
- Performance can degrade with heavy random writes
- Fragmentation on some workloads
- Complex recovery when things go wrong

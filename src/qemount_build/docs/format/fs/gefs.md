---
title: gefs
related:
  - format/fs/hjfs
  - format/fs/cwfs
detect:
  - offset: 0
    type: string
    value: gefs9.00
---

# gefs

gefs (Good Enough File System) is an experimental 9front filesystem designed
for crash safety, writable snapshots and corruption detection. Multiple named
snapshots share one storage pool and may be mounted concurrently.

## Structure

gefs uses 16 KiB blocks. The primary superblock is the first block and a backup
copy occupies the final aligned block of the device. A version string begins
the superblock; the current format is `gefs9.00`.

The superblock records block and buffer sizes, arena count, snapshot-tree
pointers, allocation-log state, feature flags, QID and generation counters,
arena roots, and a trailing hash. Metadata is held in copy-on-write pivot and
leaf blocks. Allocation arenas maintain hashed logs and reference information.

A new filesystem requires at least 128 MiB plus one block in the current
implementation.

## References

- [gefs(4)](http://man.9front.org/4/gefs)
- [Ori Bernstein, *GEFS, A Good Enough File System*](http://man.9front.org/4/gefs)


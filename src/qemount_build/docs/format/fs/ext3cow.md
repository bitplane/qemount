---
title: ext3cow
created: 2005
discontinued: 2007
related:
  - format/fs/ext3
  - format/fs/btrfs
---

# ext3cow (ext3 Copy-on-Write)

Ext3cow was a versioning filesystem based on ext3, developed by Zachary
Peterson and Randal Burns at Johns Hopkins University. It added block-level
copy-on-write versioning to ext3, providing a "time-shifting" interface that
allowed users to access past states of files and directories by adding a
temporal component to paths.

Released for Linux 2.6 in 2007, it was designed for regulatory compliance
use cases (e.g. financial record keeping). Development ceased shortly after.

## Characteristics

- Block-level copy-on-write versioning
- Time-shifting file access (view files at any past point in time)
- Based on ext3 — same on-disk format with versioning extensions
- Maximum volume size: 8 TiB (same as ext3)
- Maximum file size: 2 TiB (same as ext3)
- 255-character filenames

## On-disk Format

Ext3cow uses the standard ext3 superblock format with magic 0xEF53. The
versioning metadata (epoch counters, snapshot information) is stored in
reserved superblock fields and additional on-disk structures. There is no
distinct magic number to differentiate ext3cow from regular ext3.

## Detection

Cannot be reliably distinguished from ext3 using magic numbers alone. An
ext3cow filesystem will be detected as ext3. The versioning extensions use
reserved fields in the ext3 superblock that are not checked by standard ext3
detection.

## Guest Support

Ext3cow was never merged into mainline Linux. It required a patched kernel
(2.6.x era). The project website (ext3cow.com) and source code are no longer
available. An ext3cow filesystem can be mounted read-only as ext3 (without
versioning support) by any kernel with ext3 support.

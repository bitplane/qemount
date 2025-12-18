---
title: ext3
created: 2001
related:
  - fs/ext2
  - fs/ext4
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
        op: "<"
        value: 0x40
      - offset: 0x464
        type: le32
        op: "<"
        value: 0x8
---

# Third Extended Filesystem (ext3)

ext3 was developed by Stephen Tweedie and released in 2001, adding journaling
to ext2. It was designed for full backward compatibility - an ext3 filesystem
can be mounted as ext2 (without journaling) and vice versa.

## Characteristics

- Journaling (journal, ordered, or writeback modes)
- Online growth (no unmount required to expand)
- Block sizes: 1024, 2048, or 4096 bytes
- Maximum file size: 16GB to 2TB (depends on block size)
- Maximum filesystem size: 2TB to 32TB
- HTree indexing for large directories

## Structure

- Superblock at offset 1024 (0x400)
- Magic number 0xef53 at offset 0x438
- Journal stored as hidden inode (inode 8)
- Same block group layout as ext2
- Journal feature flag (bit 0x4) set at offset 0x45c

## Journaling Modes

- **journal** - All data and metadata journaled (safest, slowest)
- **ordered** - Metadata journaled, data written before metadata (default)
- **writeback** - Only metadata journaled (fastest, risk of stale data)

## Detection

Distinguished from ext2 by journal feature flag being set.
Distinguished from ext4 by having smaller INCOMPAT (< 0x40) and
RO_COMPAT (< 0x8) feature flags.

## Legacy

Largely superseded by ext4, but still used where ext4 features are unnecessary.

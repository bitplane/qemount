---
title: bcachefs
created: 2015
related:
  - format/fs/btrfs
  - format/fs/ext4
detect:
  - offset: 0x1018
    type: string
    value: "\xc6\x85\x73\xf6"
---

# bcachefs

bcachefs is a copy-on-write filesystem for Linux created by Kent Overstreet,
evolving from the bcache block caching layer. Development began around 2015,
with mainline Linux inclusion in kernel 6.7 (December 2023).

## Characteristics

- Copy-on-write with checksumming
- Built-in compression (lz4, gzip, zstd)
- Built-in encryption (ChaCha20/Poly1305)
- Snapshots and reflink support
- Multi-device support with replication
- Online filesystem repair
- Native RAID (1, 5, 6)

## Structure

- Superblock at offset 4096 (4KB from device start)
- Magic UUID at offset 0x1018 (written 512 bytes before superblock too)
- Redundant superblock copies (after first, and at end of device)
- B-tree based metadata storage
- Extents-based allocation

## Design Goals

- Performance of ext4
- Features of btrfs
- Reliability and stability focus
- Clean, maintainable codebase

## Comparison to btrfs

- Similar feature set (CoW, snapshots, checksums, compression)
- Different B-tree implementation
- Designed to avoid btrfs complexity issues
- Native RAID5/6 considered more stable

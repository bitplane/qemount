---
title: EROFS
created: 2018
related:
  - format/fs/squashfs
  - format/fs/cramfs
detect:
  - offset: 0x400
    type: le32
    value: 0xe0f5e1e2
---

# EROFS (Enhanced Read-Only File System)

EROFS was developed by Huawei and merged into Linux 4.19 (2018). It's designed
as a high-performance read-only filesystem optimized for modern storage,
particularly for Android system partitions and container images.

## Characteristics

- Read-only (by design)
- Multiple compression algorithms (LZ4, LZMA, DEFLATE)
- Fixed-output compression (predictable block sizes)
- Inline data for small files
- Tail packing (multiple file tails in one block)
- Sub-page block support
- Metadata deduplication

## Structure

- Superblock at offset 1024 (0x400)
- Magic number 0xE0F5E1E2 (little-endian)
- On-disk inodes (compact or extended format)
- Compressed data in fixed-output clusters
- Optional per-file compression

## Compression Modes

| Mode | Algorithm | Notes |
|------|-----------|-------|
| 0 | None | Uncompressed |
| 1 | LZ4 | Fast decompression |
| 2 | LZMA | High ratio |
| 3 | DEFLATE | zlib compatible |

## Advantages over SquashFS

- Better random read performance
- Fixed-output compression (predictable I/O)
- Lower memory overhead
- Designed for block devices (not just archives)

## Use Cases

- Android system/vendor partitions
- Container images (overlayfs lower layer)
- Embedded systems
- Read-only root filesystems

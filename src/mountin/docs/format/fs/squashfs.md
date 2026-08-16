---
title: SquashFS
created: 2002
related:
  - format/fs/cramfs
  - format/fs/erofs
detect:
  any:
    - type: string
      value: "hsqs"
      then:
        - offset: 28
          type: le16
          name: version_major
        - offset: 30
          type: le16
          name: version_minor
    - type: string
      value: "sqsh"
---

# SquashFS

SquashFS was developed by Phillip Lougher and first released in 2002. It was
merged into the Linux kernel in 2009 (version 2.6.29). It's a compressed
read-only filesystem widely used for live CDs, embedded systems, and containers.

## Characteristics

- Read-only (by design)
- High compression ratios
- Block-based compression (128KB default)
- Deduplication of files and blocks
- Supports large files (2^64 bytes)
- UIDs/GIDs, permissions, timestamps
- Symbolic links, device nodes, FIFOs
- Extended attributes

## Structure

- Superblock at offset 0
- Magic "hsqs" (little-endian) or "sqsh" (big-endian)
- Compressed metadata blocks
- Fragment table (tail ends of files)
- Inode table
- Directory table
- UID/GID lookup table

## Compression Algorithms

| ID | Algorithm | Notes                 |
|----|-----------|-----------------------|
| 1  | gzip      | Default, good balance |
| 2  | lzma      | High compression      |
| 3  | lzo       | Fast decompression    |
| 4  | xz        | Best compression      |
| 5  | lz4       | Fastest decompression |
| 6  | zstd      | Modern, configurable  |

## Version History

| Version | Changes                     |
|---------|-----------------------------|
| 1.0     | Original                    |
| 2.0     | Improved compression        |
| 3.0     | 64-bit support, fragments   |
| 4.0     | xattrs, compression options |

## Use Cases

- Live Linux distributions (Ubuntu, Fedora)
- Snap packages
- AppImages
- Docker image layers
- Embedded system firmware
- Read-only root filesystems

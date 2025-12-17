---
title: F2FS
created: 2012
related:
  - fs/ext4
  - fs/btrfs
detect:
  - offset: 0x400
    type: le32
    value: 0xf2f52010
    then:
      - offset: 0x46c
        type: string
        length: 16
        name: uuid
      - offset: 0x47c
        type: string
        name: volume_name
---

# F2FS (Flash-Friendly File System)

F2FS was developed by Samsung and released in 2012 (Linux 3.8). It's designed
specifically for NAND flash storage, optimizing for flash characteristics
like erase blocks and wear leveling.

## Characteristics

- Log-structured design (append-only writes)
- Flash-aware block allocation
- Multi-head logging
- Adaptive logging (normal vs append modes)
- Node Address Table (NAT) for indirect blocks
- Segment Information Table (SIT) for validity
- Inline data, directories, and xattrs
- Optional compression (LZO, LZ4, zstd)
- Optional encryption (fscrypt)

## Structure

- Superblock at offset 1024 (0x400)
- Magic number 0xF2F52010 (little-endian)
- Checkpoint area (transaction consistency)
- Segment Info Table (SIT)
- Node Address Table (NAT)
- Segment Summary Area (SSA)
- Main area (data and node segments)

## Key Concepts

- **Segment**: Basic unit of management (2MB default)
- **Section**: Group of segments for cleaning
- **Zone**: Group of sections
- **Node**: Inode or indirect block pointer block
- **Cleaning**: Garbage collection of invalid blocks

## Flash Optimizations

- Aligns writes to flash erase blocks
- Reduces write amplification
- Batches small writes
- Hot/cold data separation
- TRIM/discard support

## Use Cases

- Android internal storage (default since some versions)
- SD cards and eMMC
- SSDs (though ext4/XFS often preferred)
- Any NAND flash-based storage

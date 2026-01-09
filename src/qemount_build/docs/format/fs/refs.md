---
title: ReFS
created: 2012
related:
  - format/fs/ntfs
  - format/fs/btrfs
detect:
  - offset: 0
    type: string
    value: "ReFS"
    then:
      - offset: 4
        type: le16
        name: major_version
---

# ReFS (Resilient File System)

ReFS was developed by Microsoft and released with Windows Server 2012.
It was designed as a next-generation filesystem to address NTFS limitations
while maintaining compatibility with Windows storage APIs.

## Characteristics

- Copy-on-write for metadata
- Automatic integrity checking
- Allocation tiering support
- Maximum file size: 35 PB
- Maximum volume size: 35 PB
- No boot support (requires NTFS for Windows boot)
- Designed for Storage Spaces

## Structure

- "ReFS" signature at offset 0
- Superblock contains volume metadata
- B+ tree structures
- Metadata integrity streams
- Allocator tables for space management
- Checkpoint areas

## Key Features

- **Integrity Streams**: Checksums for data corruption detection
- **Block Clone**: Instant file copies (copy-on-write)
- **Sparse VDL**: Efficient virtual disk storage
- **Salvage**: Automatic corruption repair
- **Storage Spaces Integration**: Native tiering, mirroring

## Versions

| Version | Windows | Features |
|---------|---------|----------|
| 1.x | Server 2012 | Basic ReFS |
| 2.x | Server 2016 | Block clone, tiering |
| 3.x | Server 2019+ | Improved performance |

## Limitations vs NTFS

- No boot partition support
- No disk quotas
- No file compression (some versions)
- No EFS encryption
- Limited tool support

## Linux Support

No native Linux support. Very limited third-party options:
- Some forensic tools can read ReFS
- No FUSE drivers available
- Microsoft proprietary format

## Use Cases

- Hyper-V virtual machine storage
- Storage Spaces Direct
- Large file servers
- Backup targets

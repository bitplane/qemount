---
title: XFS
created: 1993
related:
  - format/fs/ext4
  - format/fs/btrfs
detect:
  - type: be32
    value: 0x58465342
    then:
      - offset: 4
        type: be32
        name: block_size
      - offset: 104
        type: be16
        name: inode_size
---

# XFS

XFS was developed by Silicon Graphics (SGI) for IRIX in 1993 and ported to
Linux in 2001. It's a high-performance 64-bit journaling filesystem designed
for scalability and parallel I/O.

## Characteristics

- 64-bit filesystem (since inception)
- Maximum file size: 8 EB
- Maximum volume size: 8 EB
- Allocation groups (parallel allocation)
- Extent-based allocation
- B+ tree directories and free space
- Metadata journaling
- Real-time I/O support (optional)
- Reflinks and deduplication (4.9+)

## Structure

- Superblock at offset 0
- Magic "XFSB" (0x58465342) at offset 0
- Allocation groups divide the filesystem
- Each AG has own free space and inode B+ trees
- Journal (log) in separate AG or external

## Key Features

- **Allocation Groups**: Parallel metadata operations
- **Delayed Allocation**: Improves contiguity
- **Extent-based**: Efficient large file handling
- **Online Defrag**: xfs_fsr tool
- **Online Resize**: Grow only (no shrink)
- **Quotas**: User, group, project

## Comparison

| Feature | XFS | ext4 |
|---------|-----|------|
| Max file | 8 EB | 16 TB |
| Max volume | 8 EB | 1 EB |
| Shrink | No | Yes |
| Reflinks | Yes | Yes |
| Default RHEL | Yes (7+) | No |

## Use Cases

- Enterprise servers
- Large file storage (media, databases)
- High-performance I/O
- RHEL/CentOS default filesystem

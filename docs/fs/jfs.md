---
title: JFS
type: fs
created: 1990
related:
  - fs/ext4
  - fs/xfs
detect:
  - offset: 0x8000
    type: string
    value: "JFS1"
    then:
      - offset: 0x8000
        type: le64
        name: block_count
      - offset: 0x8008
        type: le32
        name: block_size
---

# JFS (Journaled File System)

JFS was developed by IBM, originally for AIX in 1990. JFS2 (the version used
on Linux) was ported from OS/2 Warp and released as open source in 1999. It
was merged into Linux 2.4.18 (2002).

## Characteristics

- Metadata journaling (log-based)
- Extent-based allocation
- B+ tree directories
- Dynamic inode allocation
- Block sizes: 512, 1024, 2048, 4096 bytes
- Maximum file size: 4 PB
- Maximum volume size: 32 PB
- Variable length directory entries
- Supports large files efficiently

## Structure

- Superblock at offset 32768 (0x8000)
- Magic string "JFS1" (despite being JFS2)
- Aggregate (filesystem) and Fileset concepts
- Inline data for small files and directories
- Allocation groups for scalability

## Key Features

- **Extent-based**: Files stored as contiguous runs
- **B+ trees**: For directories and extent maps
- **Deferred allocation**: Batches metadata updates
- **Dynamic inodes**: No fixed inode count

## Journaling

JFS uses a write-ahead log for metadata:
- Log at fixed location in aggregate
- Redo-only recovery (no undo)
- Group commit for efficiency
- Typically 32MB log size

## Comparison

| Feature | JFS | ext4 | XFS |
|---------|-----|------|-----|
| Extents | Yes | Yes | Yes |
| B+ trees | Yes | H-tree | Yes |
| Dynamic inodes | Yes | No | Yes |
| Reflink | No | Yes | Yes |

## Use Cases

- Servers with large files
- AIX/OS2 migration to Linux
- Low CPU overhead journaling
- Less common today (ext4/XFS preferred)

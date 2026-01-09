---
title: LFS
created: 1992
related:
  - format/fs/nilfs2
  - format/fs/f2fs
detect:
  - type: le32
    value: 0x00070162
---

# LFS (Log-structured File System)

LFS was developed at UC Berkeley and implemented in BSD, based on the 1992
paper by Rosenblum and Ousterhout. It pioneered log-structured design where
all writes go to a sequential log, optimizing for write performance.

## Characteristics

- Log-structured (append-only writes)
- Optimized for write-heavy workloads
- Automatic garbage collection (cleaner)
- Crash recovery from checkpoints
- Maximum file size: limited by implementation
- Snapshot support

## Structure

- Magic 0x00070162 at offset 0
- Superblock with checkpoint info
- Segments contain log data
- Inode map tracks inode locations
- Segment summary for each segment
- Cleaner reclaims obsolete data

## Key Concepts

- **Segment**: Unit of log writing
- **Checkpoint**: Consistent filesystem state
- **Cleaner**: Background GC process
- **Inode Map**: Tracks moving inodes

## Design Principles

All writes append to log:
1. Buffer writes in memory
2. Write full segment to disk
3. Update checkpoint
4. Cleaner reclaims old segments

## Implementations

| System | Notes |
|--------|-------|
| BSD/LFS | Original implementation |
| NetBSD | Maintained LFS support |
| Sprite LFS | Research OS version |
| NILFS2 | Linux successor |

## Influence

LFS concepts influenced F2FS, NILFS2, and flash translation layers.
The log-structured approach is particularly suited for flash storage.

---
title: NILFS2
created: 2005
related:
  - fs/btrfs
  - fs/f2fs
detect:
  - offset: 0x406
    type: le16
    value: 0x3434
---

# NILFS2 (New Implementation of a Log-structured File System)

NILFS2 was developed by NTT (Nippon Telegraph and Telephone) and merged into
Linux 2.6.30 (2009). It's a log-structured filesystem that provides continuous
snapshotting and efficient garbage collection.

## Characteristics

- Log-structured (append-only writes)
- Continuous checkpointing (automatic snapshots)
- Unlimited snapshots (space permitting)
- Online garbage collection
- Maximum file size: 8 EB
- Maximum volume size: 8 EB
- Block sizes: 1024 to 65536 bytes

## Structure

- Superblock at offset 1024 (0x400)
- Magic 0x3434 at offset 6 within superblock
- Secondary superblock at end of device
- Segment-based log structure
- B-tree for file indexing
- Checkpoint/snapshot regions

## Key Concepts

- **Segment**: Unit of log writing (default 8MB)
- **Checkpoint**: Consistent filesystem state
- **Snapshot**: Persistent checkpoint (user-created)
- **GC**: Garbage collector reclaims obsolete segments

## Continuous Snapshotting

Every sync creates a checkpoint, providing:
- Point-in-time recovery
- No explicit backup commands needed
- Convert any checkpoint to permanent snapshot
- Instant rollback capability

## Use Cases

- Systems needing frequent backups
- Development environments (easy rollback)
- Forensic data recovery
- Versioned storage
- Flash-friendly workloads

## Considerations

- Requires garbage collection (CPU overhead)
- Full disk can block writes during GC
- Less common than ext4/XFS (smaller community)

---
title: Coda
created: 1987
related:
  - format/fs/nfs
---

# Coda

Coda is a distributed filesystem developed at Carnegie Mellon University
starting in 1987. It's descended from AFS (Andrew File System) and designed
for disconnected operation - allowing clients to work offline and sync later.

## Characteristics

- Distributed/network filesystem
- Disconnected operation support
- Client-side caching
- Optimistic replication
- Conflict resolution
- Server replication for availability

## Structure

- Client-server architecture
- Venus: client-side cache manager
- Vice: server-side file service
- Volume-based organization
- Callback-based cache coherency

## Key Features

- **Disconnected Mode**: Work offline, sync when reconnected
- **Hoarding**: Prefetch files for offline use
- **Reintegration**: Merge offline changes back to server
- **Conflict Detection**: Identify and resolve conflicting edits
- **Replication**: Servers replicate for fault tolerance

## Detection

Coda has no on-disk format — it is a distributed network filesystem
(architecturally similar to NFS). The magic number 0x73757245 ("surE") is a
VFS-only constant used by `statfs()` to identify mounted Coda filesystems; it
never appears on disk. The kernel module communicates with a userspace cache
manager (Venus) via `/dev/coda` and uses `get_tree_nodev()` (no block device).

Venus maintains a local file cache, but that uses whatever the host filesystem
is (typically ext4). There is no distinct on-disk format to detect.

## Current Status

- Still maintained as research project
- Less common than NFS or CIFS/SMB
- Influenced later distributed filesystems
- Linux client support in kernel

---
title: Coda
created: 1987
related:
  - fs/nfs
detect:
  # Network filesystem - no on-disk magic
  # Superblock magic 0x73757245 ("surE") used internally
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

## Magic Number

The Coda superblock uses magic 0x73757245, which spells "surE" in ASCII -
a playful touch from the CMU developers.

## Current Status

- Still maintained as research project
- Less common than NFS or CIFS/SMB
- Influenced later distributed filesystems
- Linux client support in kernel

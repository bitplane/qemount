---
title: OCFS2
created: 2004
related:
  - fs/gfs2
  - fs/ext4
detect:
  - offset: 0x2000
    type: string
    value: "OCFSV2"
---

# OCFS2 (Oracle Cluster File System 2)

OCFS2 is a shared-disk cluster filesystem developed by Oracle, released in
2004. It was designed for Oracle RAC (Real Application Clusters) but works
as a general-purpose cluster filesystem.

## Characteristics

- Shared-disk cluster filesystem
- POSIX compliant
- Extent-based allocation
- Journaling (JBD2-based)
- Maximum file size: 4 PB
- Maximum volume size: 4 PB
- Reflinks and deduplication

## Structure

- Superblock at block 3 (offset varies with block size)
- "OCFSV2" signature identifies filesystem
- Backup superblocks at 1GB, 4GB, 16GB, 64GB, 256GB, 1TB
- Slot-based allocation for cluster nodes
- System files in hidden directory

## Key Features

- **DLM**: Distributed lock manager
- **Heartbeat**: Node health monitoring
- **Reflinks**: Copy-on-write clones
- **Indexed Directories**: Fast lookups
- **Quotas**: User and group

## Cluster Architecture

- O2CB: Oracle's cluster stack
- Can use Pacemaker/Corosync
- Up to 255 nodes
- Fence-less for some configurations

## Use Cases

- Oracle RAC databases
- Virtualization (shared VM images)
- High availability clusters
- Shared application data

---
title: GFS2
created: 2006
related:
  - format/fs/ocfs2
  - format/fs/ext4
detect:
  - offset: 0x10000
    type: be32
    value: 0x01161970
    then:
      - offset: 0x10018
        type: be32
        value: 0x00000709
---

# GFS2 (Global File System 2)

GFS2 is a shared-disk cluster filesystem developed by Red Hat, released in
2006 as a successor to GFS. It allows multiple nodes in a cluster to access
the same storage simultaneously with full read-write capability.

## Characteristics

- Shared-disk cluster filesystem
- POSIX compliant
- Journaling (per-node journals)
- Distributed locking (DLM)
- Maximum file size: 100 TB
- Maximum volume size: 100 TB
- Online resize and quota

## Structure

- Superblock at offset 64KB (0x10000)
- Magic 0x01161970 (a date: Jan 16, 1970?)
- Version marker 0x709 at offset 0x10018
- Per-node journals
- Resource groups for allocation

## Key Concepts

- **DLM**: Distributed Lock Manager coordinates access
- **Resource Groups**: Divide space for parallel allocation
- **Journals**: Each node has its own journal
- **Fencing**: STONITH prevents split-brain

## Requirements

- Cluster infrastructure (Pacemaker/Corosync)
- Shared storage (SAN, iSCSI, FC)
- Fencing mechanism
- DLM running on all nodes

## Use Cases

- High availability clusters
- Active-active configurations
- Shared storage for VMs
- Red Hat Enterprise Linux clusters

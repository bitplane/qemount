---
title: ZFS
created: 2005
related:
  - format/fs/btrfs
  - format/fs/bcachefs
detect:
  - offset: 0x2000
    type: le64
    value: 0x00bab10c
    name: uberblock_magic
  - offset: 0x4000
    type: le64
    value: 0x00bab10c
---

# ZFS (Zettabyte File System)

ZFS was developed by Sun Microsystems and released in 2005. After Oracle
acquired Sun, the open-source OpenZFS project forked and continues active
development for Linux, FreeBSD, and other platforms.

## Characteristics

- Combined volume manager and filesystem
- Copy-on-write (transactional)
- 128-bit addressing
- Checksums on all data and metadata
- Maximum file size: 16 EB
- Maximum volume size: 256 ZB (theoretical)
- Native RAID (RAID-Z, mirrors)
- Compression, deduplication, encryption

## Structure

- Vdev labels at start and end of device
- Uberblock array in labels
- Magic 0x00BAB10C in uberblock
- MOS (Meta Object Set) contains all metadata
- DMU (Data Management Unit) layer
- ZIO (ZFS I/O) handles device access

## Key Features

- **Snapshots**: Instant, space-efficient
- **Clones**: Writable snapshots
- **Send/Receive**: Incremental replication
- **Scrub**: Background integrity checking
- **Self-Healing**: Automatic repair with redundancy
- **ARC**: Adaptive replacement cache

## RAID Levels

| Level | Parity | Min Disks |
|-------|--------|-----------|
| RAID-Z1 | Single | 3 |
| RAID-Z2 | Double | 4 |
| RAID-Z3 | Triple | 5 |
| Mirror | N-way | 2+ |

## Platform Support

- **FreeBSD**: Native support since 7.0
- **Solaris/illumos**: Native
- **Linux**: OpenZFS module (not in mainline kernel due to licensing)
- **NetBSD**: Native port
- **macOS**: OpenZFS on macOS

## Linux Considerations

ZFS is not included in the Linux kernel due to CDDL/GPL license
incompatibility. It must be built as a separate kernel module via
OpenZFS or distribution packages (Ubuntu, etc.).

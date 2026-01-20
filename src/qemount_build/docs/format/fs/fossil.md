---
title: Fossil
created: 2002
related:
  - format/pt/plan9
  - format/fs/kfs
  - format/fs/cwfs
detect:
  - offset: 0
    type: be32
    value: 0x3776ae89
    name: header_magic
---

# Fossil Filesystem

Fossil is the default filesystem for Plan 9 from Bell Labs, designed by
Sean Quinlan, Jim McKie, and Russ Cox. It provides snapshot/archival
capabilities and integrates with Venti for permanent storage.

## Characteristics

- Snapshot storage (automatic or on-demand)
- Venti integration for archival
- 8KB default block size
- 9P protocol interface
- Runs as user-space daemon
- Copy-on-write for snapshots

## Structure

### Header Block (offset 0)

| Offset | Size | Field |
|--------|------|-------|
| 0 | 4 | magic (0x3776ae89) |
| 4 | 2 | version |
| 6 | 2 | blockSize |
| 8 | 4 | super (block offset) |
| 12 | 4 | label (block offset) |
| 16 | 4 | data (block offset) |
| 20 | 4 | end (block offset) |

### Superblock

| Offset | Size | Field |
|--------|------|-------|
| 0 | 4 | magic (0x2340a3b1) |
| 4 | 2 | version |
| 6 | 4 | epochLow |
| 10 | 4 | epochHigh |
| 14 | 8 | qid (next to allocate) |
| 22 | 4 | active (root block) |
| 26 | 4 | next |
| 30 | 4 | current |
| 34 | 20 | last (Venti score) |
| 54 | 128 | name |

## MBR Partition Type

Fossil lives inside a Plan 9 partition (type 0x39), which contains an
ASCII partition table subdividing it into subpartitions including
"fossil", "venti", "9fat", etc.

## Snapshots

Fossil can take snapshots of the entire filesystem:
- On demand via console commands
- Automatically at user-set intervals
- Old snapshots removed when disk fills
- Permanent snapshots archived to Venti

## Venti Integration

Venti is a companion archival storage system:
- Content-addressed block storage
- Permanent, immutable storage
- Deduplication by content hash
- Fossil uses Venti as backup target

## Other Plan 9 Filesystems

| Name | Description |
|------|-------------|
| KFS | Original Ken Thompson filesystem, 6KB blocks |
| CWFS | Cached WORM File Server, 16KB blocks |
| 9fat | FAT partition for boot files |

## Current Status

- Native to Plan 9 and 9front
- plan9port provides tools for other Unix systems
- No Linux kernel driver
- Would require emulation or native implementation

## References

- [Fossil paper (PDF)](http://www.scs.stanford.edu/06wi-cs240d/lab/fossil.pdf)
- [Plan 9 fossil(4) man page](https://9p.io/magic/man2html/4/fossil)

---
title: CWFS
created: 1990
related:
  - format/fs/fossil
  - format/fs/kfs
  - format/pt/plan9
---

# CWFS (Cached WORM File Server)

CWFS is a Plan 9 filesystem designed for optical jukeboxes and WORM
(Write Once Read Many) media. It uses a disk cache to overcome the
write-once limitation and provides automatic daily snapshots.

## Characteristics

- 16KB blocks (for compatibility with existing systems)
- 32-bit disk addresses
- WORM media support with disk caching
- Automatic daily snapshots ("dumps")
- User-space daemon
- 9P protocol interface
- Compatible with original fs(4)

## Architecture

CWFS maintains three logical filesystems:

### other
Simple disk-based filesystem, similar to KFS. Used for scratch space
or data that doesn't need archival.

### main
WORM-based filesystem with disk cache:
- Modified blocks cached on disk
- Cache overcomes write-once limitation
- Daily dumps move cache to WORM
- Recently accessed blocks cached for performance

### dump
Read-only snapshot filesystem:
- Created when main is dumped
- Roots named `/yyyy/mmdd` (date format)
- Suffix `s` added for multiple daily dumps
- Provides point-in-time recovery

## Detection

CWFS has no magic number. Like KFS, it relies on context (partition
naming in Plan 9's ASCII partition table) for identification.

## 64-bit Variant

In 2004, Geoff Collyer created a 64-bit version:
- 64-bit file offsets, sizes, and block numbers
- Triple and quadruple indirect blocks
- Filename components extended from 27 to 55 bytes

## History

- 1990: Original file server supports WORM
- Used for Bell Labs' main file servers
- Designed for magneto-optical jukeboxes
- 2002: Fossil becomes default, CWFS for legacy systems
- 2004: 64-bit version created

## Current Status

- Primarily for managing existing optical jukebox systems
- Block size and address size fixed at compile time
- Not recommended for new deployments
- No Linux kernel driver
- Fossil preferred for new installations

## References

- [cwfs(4) man page](http://man.cat-v.org/plan_9/4/cwfs)
- [64-bit File Server paper](https://9p.io/sys/doc/fs/fs.html)

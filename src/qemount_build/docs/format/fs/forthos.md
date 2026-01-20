---
title: ForthOS
created: 2000
related:
  - format/fs/vstafs
---

# ForthOS Filesystem

ForthOS is a standalone Forth operating system for PC by Andy Valencia,
a port of eForth. It includes command line, compiler, debugger, editor,
and filesystem. The same author created VSTa microkernel which shares
the partition type.

## Characteristics

- 4096-byte blocks
- Traditional Forth block-based storage
- Contiguous allocation
- Source/shadow screen model
- Block numbers as primary access mechanism
- Directories as "mini-filesystems"

## Block Structure

Each 4096-byte block contains:

| Offset | Size | Purpose |
|--------|------|---------|
| 0 | 2000 | Source screen (80×25 characters) |
| 2000 | 2000 | Shadow screen (comments/docs) |
| 4000 | 96 | Filesystem metadata |

## Allocation

- Contiguous block allocation
- Size specified at creation time
- Files/directories "carved out" from parent
- Growth modifies minimal data structures

## Directory Structure

Directories function as mini-filesystems:
- One block for directory contents
- Remaining allocated blocks for children
- Entries store name + starting block number

## MBR Partition Type

| Type | Description |
|------|-------------|
| 0x9E | ForthOS / VSTa |

Both ForthOS and VSTa (same author) use partition type 0x9E (158).

## Detection

No documented magic number. Would need to identify by:
- Block structure at offset 0
- Valid Forth source in first 2000 bytes
- Filesystem metadata in last 96 bytes of blocks

## VSTa

VSTa (Valencia's Simple Tasker) is a microkernel OS by the same author,
inspired by QNX and Plan 9. It has its own native filesystem (vstafs)
but is no longer developed. Both share partition type 0x9E.

## Current Status

- ForthOS: Semi-active, author mentioned modernization efforts
- VSTa: No longer developed
- Source available at sources.vsta.org
- No Linux kernel driver
- Interesting target for 9p porting

## References

- [ForthOS Home](https://sources.vsta.org/forthos/)
- [ForthOS Filesystem](http://sources.vsta.org/forthos/fs.html)
- [VSTa Home](https://www.vsta.org/)
- [ArchiveOS: ForthOS](https://archiveos.org/forthos/)

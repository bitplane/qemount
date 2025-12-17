---
title: Amiga SFS
type: fs
created: 1998
related:
  - fs/amiga-ffs
  - fs/amiga-ofs
  - pt/amiga-rdb
detect:
  - offset: 0
    type: string
    value: "SFS\x00"
    name: sfs_v1
  - offset: 0
    type: string
    value: "SFS\x02"
    name: sfs_v2
---

# SFS (Smart File System)

SFS was developed by John Hendrikx and released in 1998 as a modern
replacement for FFS on Amiga systems. It became popular in the late
Amiga era and is still used in AROS and MorphOS.

## Characteristics

- Transaction-based (crash-safe)
- No filesystem check needed after crash
- Dynamic directory hashing
- Faster than FFS on large directories
- Maximum file size: 4 GB (v1), larger in v2
- Maximum volume size: 2 TB+
- Object-based design

## Structure

- Root block at start of partition
- Magic "SFS\x00" (v1) or "SFS\x02" (v2)
- Bitmap for allocation
- B-tree for objects
- Transaction buffer

## Versions

| Version | Features |
|---------|----------|
| SFS 1.x | Original release |
| SFS 2.x | 64-bit support, larger files |

## Key Features

- **Transactions**: All changes atomic
- **No fsck**: Instant recovery after crash
- **Efficient**: Good performance on HDDs
- **Flexible**: Works well with large disks

## Platform Support

- **AmigaOS 3.x+**: With installer
- **AmigaOS 4.x**: Native support
- **MorphOS**: Native support
- **AROS**: Native support
- **Linux**: No support

## Linux Considerations

Linux has no SFS driver. Accessing SFS partitions requires:
- AROS guest (best option for qemount)
- UAE emulation
- Native Amiga hardware

## Why AROS?

AROS is the best guest for SFS because:
- Open source
- Native SFS implementation
- Runs on x86 (and 68k for classic compatibility)
- Can access Amiga disk images directly

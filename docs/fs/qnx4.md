---
title: QNX4
type: fs
created: 1990
related:
  - fs/qnx6
detect:
  - offset: 0
    type: le16
    value: 0x002f
---

# QNX4 Filesystem

The QNX4 filesystem was used by QNX 4.x and QNX Neutrino RTOS. It uses
extent-based allocation for efficient storage of contiguous files, which
is important for real-time applications.

## Characteristics

- Extent-based allocation
- Contiguous file storage
- Small footprint
- Fast access times
- Maximum file size: 2 GB
- Maximum volume size: 2 GB (4 GB with extensions)

## Structure

- Magic 0x002F at offset 0
- Loader block at block 0 (boot info)
- Root block at block 1 (volume inode)
- Bitmap for allocation
- Extent-based files

## Extent Organization

Files stored in contiguous extents:
- First extent in inode
- Additional extents linked
- Minimizes fragmentation
- Fast sequential access

## Real-Time Features

- Predictable access times
- Minimal overhead
- Suitable for embedded systems
- POSIX compliant

## Linux Support

Linux has read-only QNX4 filesystem support (fs/qnx4/).
Useful for accessing QNX 4.x system disks.

## Legacy

QNX4 filesystem was superseded by QNX6 filesystem (Power-Safe)
in newer QNX versions, but QNX4 support remains for compatibility.

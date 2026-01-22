---
title: ShagOS
created: 1997
discontinued: 2000
---

# ShagOS Filesystem

ShagOS is a portable, object-oriented microkernel operating system written
in C by Frank Barrus at Rochester Institute of Technology. It ran on PCs
and MicroVAXes.

## MBR Partition Types

| Type | Description       |
|------|-------------------|
| 0xAE | ShagOS filesystem |
| 0xAF | ShagOS swap       |

## Components

- **ShagOS Classic**: Microkernel OS (v0.37)
- **SOLO**: Boot loader with filesystem support, ramdisk, gzip decompression
- **DECO**: Dynamic C++ to C++ compiler (thesis project)

## Current Status

- Development stalled around 2000
- Source code ~300KB available
- Filesystem format undocumented
- No Linux kernel driver

## References

- [ShagWare Software](https://www.csh.rit.edu/~shaggy/software.html)
- [ArchiveOS: ShagOS](https://archiveos.org/shagos/)

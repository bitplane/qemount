---
title: THEOS
created: 1983
discontinued: 2010
---

# THEOS Filesystem

THEOS (THE Operating System) is a multiuser, multitasking operating system
founded by Timothy Williams in 1983. It evolved from OASIS, a Z80-based
microcomputer OS. The name "THEOS" comes from Greek for "God".

## Characteristics

- 1KB (1024 byte) data blocks
- Integrated ISAM, Direct, and Keyed file structures
- Multiuser with account-based security
- Public and private file ownership
- Case-preserving, case-insensitive filenames

## History

- 1980: OASIS released for Z80 systems
- 1982: Renamed THEOS for IBM PC/AT launch
- 1983: THEOS founded by Timothy Williams
- Version 3.2: Classic release
- Version 4.0: Extended partition support
- Version 5.0: Large File System (LFS), Long File Names (LFN)
- 2010s: Largely obsolete

## MBR Partition Types

| Type | Description                    |
|------|--------------------------------|
| 0x38 | THEOS                          |
| 0x3B | THEOS ver 4 extended partition |

## Features

### Version 4
- Extended partition support
- 8x8 filename limit

### Version 5 (LFS)
- Long File Names (no 8x8 limit)
- Large File System
- Boot from LBA devices (no 1024 cylinder limit)
- Integrated networking (TNFS via SMB/CIFS)

## Detection

No known magic number documented. The filesystem format is proprietary
and would require reverse engineering or access to THEOS documentation.

## Current Status

- Proprietary, closed source
- No Linux kernel driver
- No known open source implementation
- Disk images may exist in archives
- Would require reverse engineering to support

## References

- [THEOS/OASIS Users Handbook (1985)](http://www.bitsavers.org/pdf/phaseOneSystems/THEOS_OASIS_Users_Handbook_1985.pdf)
- [OSnews: Introducing THEOS](https://www.osnews.com/story/7388/introducing-the-theos-operating-system/)

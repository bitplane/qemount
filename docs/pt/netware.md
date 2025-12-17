---
title: NetWare
created: 1983
related:
  - pt/mbr
detect:
  - offset: 510
    type: le16
    value: 0xAA55
    then:
      - offset: 0x1C2
        type: u8
        value: 0x65
        name: netware_386
      - offset: 0x1C2
        type: u8
        value: 0x64
        name: netware_286
---

# NetWare Partition Table

Novell NetWare uses specific MBR partition type codes. NetWare had its
own filesystem (NWFS, later NSS) but used standard MBR for partitioning.

## Characteristics

- Standard MBR partitioning
- Specific partition type codes
- NetWare filesystem inside partition
- Dominant in 1990s LANs

## Partition Types

| Type | Description |
|------|-------------|
| 0x64 | NetWare 286 |
| 0x65 | NetWare 386 / NWFS |
| 0x66 | NetWare 386 (alt) |
| 0x67 | NetWare (Novell) |
| 0x68 | NetWare (Novell) |
| 0x69 | NetWare 5+ / NSS |

## Filesystems

| Filesystem | Era | Features |
|------------|-----|----------|
| NetWare 286 | 1985 | Basic |
| NWFS (Traditional) | 1989 | NetWare 3.x/4.x |
| NSS | 1998 | NetWare 5+, 64-bit |

## Structure

Standard MBR, with NetWare volumes inside partitions.
NetWare has its own volume management within partitions.

## NSS (Novell Storage Services)

NSS introduced with NetWare 5:
- 64-bit filesystem
- Journaling
- Pool-based storage
- Still used in OES (Open Enterprise Server)

## Linux Support

Linux can recognize NetWare partition types in MBR.
No native NWFS/NSS filesystem support, but:
- ncpfs: NetWare Core Protocol (network access)
- Some forensic tools can read NWFS

## Historical Note

Novell NetWare dominated file/print serving in the late 1980s
and 1990s before Windows NT Server took over. NetWare 6.5 (2003)
was the last major release before Novell shifted to Linux (OES).

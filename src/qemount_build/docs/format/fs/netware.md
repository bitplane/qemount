---
title: NetWare (NWFS)
created: 1983
discontinued: 2010
related:
  - format/fs/nss
detect:
  any:
    # NWFS 386 (v3.x+): HOTFIX header at sector 32 (offset 0x4000)
    - offset: 0x4000
      type: string
      value: "HOTFIX00"
    # NWFS 286 (v2.x): magic 0xFADE at sector 16 offset 2
    - offset: 0x2002
      type: le16
      value: 0xfade
---

# NetWare

Novell NetWare was the dominant network operating system for corporate LANs
in the late 1980s and 1990s. It featured advanced filesystem capabilities
that were ahead of their time, including journaling and sophisticated
permissions.

## MBR Partition Types

| Type | Name         | Notes                           |
|------|--------------|---------------------------------|
| 0x64 | NetWare 286  | v2.x, 16-bit, simpler structure |
| 0x65 | NetWare 386  | v3.x+, 32-bit, more advanced    |
| 0x67 | Novell       | Unknown specific use            |
| 0x68 | Novell       | Unknown specific use            |
| 0x69 | Novell       | Unknown specific use            |

Multiple partition types were allocated to Novell for different product
versions. The traditional NetWare File System (NWFS) was replaced by NSS
(Novell Storage Services) in NetWare 5, which is a separate filesystem.

## Characteristics

- Transaction Tracking System (TTS) - journaling before it was mainstream
- Trustee rights - sophisticated permission system
- Multiple namespace support (DOS, Mac, NFS, OS/2 simultaneously)
- Extended attributes
- File compression (v4+)
- Suballocation - efficient small file storage
- Data migration - HSM support

## Structure

### NWFS 386 (NetWare 3.x+)

Configurable block size (1KB-64KB). Partition layout:

| Sector | Offset | Description                                    |
|--------|--------|------------------------------------------------|
| 32     | 0x4000 | Hotfix area: string `"HOTFIX00"` (4 copies)    |
| 33     | 0x4200 | Mirror area: string `"MIRROR00"`               |
| varies | varies | Volume area: string `"NetWare Volumes\0"`      |
| varies | varies | Data area: FAT, directory entries, file data    |

- 128-byte directory entries
- FAT-based block allocation (not DOS FAT)
- Turbo FAT for large files
- Volumes can span multiple partitions

### NWFS 286 (NetWare 2.x)

Fixed 4KB block size. Simpler layout:

| Sector | Description                                        |
|--------|----------------------------------------------------|
| 0      | Boot sector with partition table                   |
| 1-14   | Loader                                             |
| 15     | Control sector                                     |
| 16     | Volume information (magic `0xFADE` at offset 2)    |

- Volume segments can span multiple partitions
- Directory Entry Table (DET)
- Extended attributes stored separately

## History

- 1983: Novell NetWare released (S-Net origins)
- 1985: NetWare 286 (v2.x)
- 1989: NetWare 386 (v3.x) - 32-bit
- 1993: NetWare 4.x - NDS directory services
- 1998: NetWare 5.x - NSS filesystem
- 2003: Novell acquired by various companies
- 2010: Effectively discontinued (replaced by OES on Linux)

## Current Status

- **ncpfs**: Linux can mount NetWare volumes over network (NCP protocol)
- **nwfs-tools**: Some userspace tools exist
- No mainline Linux kernel driver for native disk access
- Format partially reverse-engineered
- Server images likely exist in archives

## Implementation Notes

Possible approaches for qemount support:

1. **Native driver**: Reverse engineer on-disk format, implement reader
2. **Emulation**: Run NetWare in VM, export via NCP
3. **nwfs-tools**: Adapt existing userspace tools

The filesystem format is proprietary but has been partially documented
through reverse engineering efforts over the years.

## References

- Multiple namespace support was innovative - same file accessible as
  8.3 DOS name, long Mac name, and Unix name simultaneously
- TTS predated ext3 journaling by over a decade

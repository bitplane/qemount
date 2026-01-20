---
title: NetWare
created: 1983
discontinued: 2010
---

# NetWare

Novell NetWare was the dominant network operating system for corporate LANs
in the late 1980s and 1990s. It featured advanced filesystem capabilities
that were ahead of their time, including journaling and sophisticated
permissions.

## MBR Partition Types

| Type | Name | Notes |
|------|------|-------|
| 0x64 | NetWare 286 | v2.x, 16-bit, simpler structure |
| 0x65 | NetWare 386 | v3.x+, 32-bit, more advanced |
| 0x67 | Novell | Unknown specific use |
| 0x68 | Novell | Unknown specific use |
| 0x69 | Novell | Unknown specific use |

Multiple partition types were allocated to Novell, possibly for different
volume types (system, data) or product versions. NSS (Novell Storage
Services) in v5+ typically uses 0x65.

## Characteristics

- Transaction Tracking System (TTS) - journaling before it was mainstream
- Trustee rights - sophisticated permission system
- Multiple namespace support (DOS, Mac, NFS, OS/2 simultaneously)
- Extended attributes
- File compression (v4+)
- Suballocation - efficient small file storage
- Data migration - HSM support

## Structure

NetWare uses a volume-based structure:

- Volume segments can span multiple partitions
- Directory Entry Table (DET)
- File Allocation Table (FAT) - not DOS FAT, different format
- Turbo FAT for large files
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

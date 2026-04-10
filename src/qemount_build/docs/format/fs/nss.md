---
title: NSS (Novell Storage Services)
created: 1998
discontinued: 2010
related:
  - format/fs/netware
detect:
  - offset: 0x1000
    type: string
    value: "SPB5"
---

# NSS (Novell Storage Services)

NSS was introduced in NetWare 5 (1998) as the successor to the traditional
NetWare File System (NWFS). It was a complete redesign using a balanced tree
architecture instead of NWFS's FAT-like allocation tables. NSS continued as
the primary filesystem for Novell Open Enterprise Server (OES) on both
NetWare and Linux kernels.

## Characteristics

- Balanced tree (B-tree) based metadata
- Journaling with transaction logging
- Storage pools and logical volumes
- Maximum volume size: 8TB (later expanded to 8EB theoretical)
- Maximum file size: 8TB
- Compression and deduplication
- Snapshot support (SAN-backed)
- Cluster-aware (Novell Cluster Services)
- Multiple namespace support (DOS, Mac, NFS, Long)
- NSS volumes can span multiple partitions/devices
- Near-instant mount times (no FAT scan)
- Salvageable files (deleted file recovery)

## Disk Layout

NSS uses a layered storage model:

1. **Partitions**: Physical disk space (MBR type 0x65)
2. **Storage Pools**: Aggregation of partitions
3. **Volumes**: Logical filesystems within pools

The on-disk format is proprietary and not well-documented publicly. No
filesystem-level magic number has been identified for detection independent
of the partition table.

## Detection

NSS pool superblock at offset 4096 (0x1000) starts with the ASCII string
`SPB5`. This is confirmed by libblkid (`superblocks/netware.c`) which
registers it as filesystem type `"nss"`.

The superblock structure includes version fields at +4/+6 (uint16 LE),
a 16-byte internal UUID at +16, and a UTF-16LE pool name at a later offset.

This distinguishes NSS from traditional NWFS, which uses `HOTFIX00` at
offset 0x4000. Both share MBR partition type 0x65.

## History

- 1998: NSS introduced in NetWare 5.0
- 2003: NSS ported to Linux (OES 1.0)
- 2005: OES 2.0, NSS on SLES
- 2010: NetWare discontinued, NSS continues on OES/Linux

## Guest Support

NSS on NetWare requires a NetWare guest. NSS on Linux (OES) uses a kernel
module that was never open-sourced. No standalone tools exist for creating
or reading NSS volumes outside of NetWare/OES.

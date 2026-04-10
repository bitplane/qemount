---
title: AdvFS
created: 1993
discontinued: 2010
related:
  - format/fs/ufs1
  - format/fs/files11
detect:
  - offset: 0x255c
    type: le32
    value: 0x11081953
---

# AdvFS (Advanced File System)

AdvFS was developed by Digital Equipment Corporation in the late 1980s for
OSF/1 (later Digital UNIX, then Tru64 UNIX). It was a sophisticated
journaling filesystem with features that were ahead of its time, including
storage domains, filesets, snapshots, and striping — concepts that later
appeared in ZFS and btrfs.

HP open-sourced AdvFS under GPLv2 in 2008 after acquiring DEC via Compaq,
but a Linux port was never completed.

## Characteristics

- Logging/journaling for crash recovery
- Storage domains: pools of volumes
- Filesets: logical filesystems within a domain
- Copy-on-write snapshots (clonesets)
- Online defragmentation
- Striping across volumes
- Per-file extent-based allocation
- Bitfile metadata table (BMT) — similar concept to NTFS MFT
- Tag-based file identification

## Disk Layout

AdvFS reserves the first 16 blocks (8KB) for boot and label areas.
The "fake superblock" occupies blocks 8-15 (offset 0x1000-0x1FFF on
Tru64, 0x2000-0x3FFF using 512-byte blocks). This is a UFS-compatible
structure that allows non-AdvFS tools to identify the volume.

### Reserved Blocks

| Blocks  | Offset  | Purpose                                |
|---------|---------|----------------------------------------|
| 0-7     | 0x0000  | Disk label, boot blocks                |
| 8-15    | 0x1000  | Fake superblock (UFS-compatible)       |
| 16+     | 0x2000  | RBMT (Reserved Bitfile Metadata Table) |

### Fake Superblock

The fake superblock mimics a UFS superblock layout to allow identification
by generic tools. The AdvFS magic is embedded within it:

- **Offset 0x255C** (block 16 start + 1372 bytes): `0x11081953` (little-endian 32-bit)

The magic value `0x11081953` likely encodes the date November 8, 1953.

### On-disk Magic Numbers (Gen2/HP-UX)

The HP-UX port introduced a new magic number scheme for internal structures:

| Magic        | Structure                    |
|--------------|------------------------------|
| 0xADF00101   | RBMT page                    |
| 0xADF00102   | BMT page                     |
| 0xADF00103   | Storage bitmap               |
| 0xADF00104   | Root tag file page            |
| 0xADF00105   | Tag file page                |
| 0xADF00106   | Log page                     |

## Detection

Magic number `0x11081953` at absolute offset 0x255C (little-endian 32-bit).
This is at byte 1372 within the fake superblock which starts at block 16
(offset 0x2000 with 512-byte blocks).

## Guest Support

AdvFS requires Tru64 UNIX (Alpha architecture). QEMU can emulate Alpha
(qemu-system-alpha), and some versions of Tru64 are known to boot under
QEMU. No Linux driver exists. The source code is available at
SourceForge (advfs) and GitHub (TheSledgeHammer/AdvFS) under GPLv2.

Creating test images would require running Tru64 under QEMU or writing
a minimal mkfs based on the open-source code.

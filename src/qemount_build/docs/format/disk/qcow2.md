---
title: QCOW2
created: 2008
related:
  - format/disk/qcow
  - format/disk/qed
  - format/disk/raw
detect:
  - offset: 0
    type: be32
    value: 0x514649fb
    name: "QCOW2"
    then:
      - offset: 4
        type: be32
        op: ">="
        value: 2
---

# QEMU Copy-On-Write v2 (QCOW2)

QCOW2 is QEMU's native disk image format, introduced in 2008 as a replacement
for the original QCOW format. It's the recommended format for QEMU/KVM virtual
machines.

## Characteristics

- Sparse allocation (only used space stored)
- Internal snapshots
- Zlib or zstd compression
- AES or LUKS encryption
- Backing files (copy-on-write chains)
- Maximum size: 2^63 bytes (theoretical)
- Cluster sizes: 512 bytes to 2 MB (default 64 KB)

## Structure

- Magic: `QFI\xfb` (0x514649fb) at offset 0
- Version field at offset 4 (2 for qcow2, 3 for qcow2 with extended features)
- Header with cluster size, L1 table location, etc.
- Two-level lookup table (L1 → L2 → data clusters)
- Reference counting for snapshots
- Optional feature areas

## Header Fields

| Offset | Size | Field                 |
|--------|------|-----------------------|
| 0x00   | 4    | Magic (0x514649fb)    |
| 0x04   | 4    | Version (2 or 3)      |
| 0x08   | 8    | Backing file offset   |
| 0x10   | 4    | Backing file size     |
| 0x14   | 4    | Cluster bits (log2)   |
| 0x18   | 8    | Virtual size          |
| 0x20   | 4    | Crypt method          |
| 0x24   | 4    | L1 size               |
| 0x28   | 8    | L1 table offset       |
| 0x30   | 8    | Refcount table offset |

## Detection

Magic bytes `QFI\xfb` at offset 0, followed by version >= 2. Version 2 is the
original qcow2, version 3 added feature flags for extended features like lazy
refcounts and metadata checksums.

## Features

- **Snapshots**: Internal or external, with qemu-img snapshot command
- **Compression**: Per-cluster, transparent read, write converts to uncompressed
- **Encryption**: LUKS format recommended over legacy AES
- **Backing files**: Create differencing disks for templates

## Tools

```sh
# Create 100GB qcow2 image
qemu-img create -f qcow2 disk.qcow2 100G

# Convert raw to qcow2
qemu-img convert -f raw -O qcow2 disk.img disk.qcow2

# Create snapshot
qemu-img snapshot -c snap1 disk.qcow2

# Check image
qemu-img check disk.qcow2
```

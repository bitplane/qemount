---
title: QED
created: 2010
discontinued: 2014
related:
  - format/disk/qcow2
  - format/disk/qcow
detect:
  - offset: 0
    type: le32
    value: 0x00444551
    name: "QED"
---

# QEMU Enhanced Disk (QED)

QED was introduced as a simpler, faster alternative to QCOW2. It was designed
to offer better performance by removing features like compression and
encryption. The format is now deprecated in favor of QCOW2.

## Characteristics

- Sparse allocation
- Backing files (copy-on-write)
- No compression
- No encryption
- No internal snapshots
- Designed for performance
- Deprecated since ~2014

## Why Deprecated

QCOW2 performance improved significantly, making QED's advantages negligible.
QCOW2's additional features (snapshots, compression, encryption) made it more
versatile. The QEMU project recommends using QCOW2 for all new deployments.

## Structure

- Magic: `QED\0` (0x00444551) at offset 0
- Simple header with cluster size, table offset
- Two-level lookup similar to qcow2
- No refcounting (simpler but no snapshots)

## Header Fields

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 4 | Magic (QED\0) |
| 0x04 | 4 | Cluster size |
| 0x08 | 4 | Table size |
| 0x0C | 4 | Header size |
| 0x10 | 8 | Features |
| 0x18 | 8 | Compat features |
| 0x20 | 8 | Autoclear features |
| 0x28 | 8 | L1 table offset |
| 0x30 | 8 | Image size |
| 0x38 | 4 | Backing file offset |
| 0x3C | 4 | Backing file size |

## Detection

Little-endian magic `QED\0` (0x00444551) at offset 0.

## Migration

Convert to qcow2:

```sh
qemu-img convert -f qed -O qcow2 disk.qed disk.qcow2
```

## QEMU Support

Still supported for reading existing images, but don't create new ones:

```sh
# Don't do this
qemu-img create -f qed disk.qed 100G  # Use qcow2 instead
```

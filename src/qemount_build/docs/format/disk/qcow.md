---
title: QCOW
created: 2004
discontinued: 2008
related:
  - format/disk/qcow2
  - format/disk/raw
detect:
  - offset: 0
    type: be32
    value: 0x514649fb
    name: "QCOW"
    then:
      - offset: 4
        type: be32
        value: 1
---

# QEMU Copy-On-Write v1 (QCOW)

The original QCOW format was introduced in QEMU around 2004. It has been
superseded by QCOW2 and is considered legacy.

## Characteristics

- Sparse allocation
- Zlib compression
- AES encryption (weak, legacy)
- Backing files
- No snapshots (unlike qcow2)
- Single-level cluster lookup (simpler than qcow2)

## Structure

- Magic: `QFI\xfb` (0x514649fb) at offset 0
- Version: 1 at offset 4
- Simpler header than qcow2
- Single-level lookup table

## Header Fields

| Offset | Size | Field               |
|--------|------|---------------------|
| 0x00   | 4    | Magic (0x514649fb)  |
| 0x04   | 4    | Version (1)         |
| 0x08   | 8    | Backing file offset |
| 0x10   | 4    | Backing file size   |
| 0x14   | 4    | Mtime               |
| 0x18   | 8    | Virtual size        |
| 0x20   | 1    | Cluster bits        |
| 0x21   | 1    | L2 bits             |
| 0x24   | 4    | Crypt method        |
| 0x28   | 8    | L1 table offset     |

## Detection

Same magic as qcow2 (`QFI\xfb`) but version field at offset 4 is 1 instead of
2 or 3.

## Migration

Convert to qcow2 for continued use:

```sh
qemu-img convert -f qcow -O qcow2 old.qcow new.qcow2
```

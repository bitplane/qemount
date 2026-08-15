---
title: Parallels
created: 2006
related:
  - format/disk/vmdk
  - format/disk/vdi
detect:
  any:
    - offset: 0
      type: string
      value: "WithoutFreeSpace"
      name: "Parallels original"
    - offset: 0
      type: string
      value: "WithouFreSpacExt"
      name: "Parallels extended"
---

# Parallels Disk Image

Parallels Desktop uses its own disk image format (HDD) for virtual machines
running on macOS.

## Characteristics

- Expanding (sparse) and plain (pre-allocated) types
- Snapshots via separate files
- Maximum size: 2 TB typical
- Optimized for macOS

## Types

- **Expanding**: Grows as data is written
- **Plain**: Pre-allocated to full size

## Structure

- Signature at offset 0
- Header with version, disk size, block size
- Block allocation table
- Data blocks

## Header Fields

| Offset | Size | Field               |
|--------|------|---------------------|
| 0x00   | 16   | Signature           |
| 0x10   | 4    | Version             |
| 0x14   | 4    | Heads               |
| 0x18   | 4    | Cylinders           |
| 0x1C   | 4    | Tracks              |
| 0x20   | 4    | Sectors             |
| 0x24   | 4    | Block size          |
| 0x28   | 8    | Disk size (sectors) |

## Detection

String at offset 0:
- `"WithoutFreeSpace"` - Original format
- `"WithouFreSpacExt"` - Extended format (current)

## QEMU Support

QEMU can read Parallels images:

```sh
qemu-system-x86_64 -drive file=disk.hdd,format=parallels
```

## Tools

```sh
# Convert Parallels to qcow2
qemu-img convert -f parallels -O qcow2 disk.hdd disk.qcow2
```

## File Extension

Parallels images typically use `.hdd` extension and are stored inside `.pvm`
virtual machine bundles.

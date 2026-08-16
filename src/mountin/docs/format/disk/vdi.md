---
title: VDI
created: 2007
related:
  - format/disk/vmdk
  - format/disk/vhd
  - format/disk/qcow2
detect:
  - offset: 0x40
    type: le32
    value: 0xbeda107f
    name: "VDI"
---

# VirtualBox Disk Image (VDI)

VDI is the native disk image format for Oracle VirtualBox, introduced when
VirtualBox was created by Innotek in 2007.

## Characteristics

- Sparse allocation (dynamic images)
- Fixed-size option (pre-allocated)
- Snapshots (via differencing images)
- Maximum size: 2 TB (MBR) or larger with GPT
- No built-in compression
- No built-in encryption

## Structure

- File info header at offset 0
- Magic signature at offset 0x40
- UUID identifiers for image and snapshots
- Block allocation table
- Data blocks

## Header Fields

| Offset | Size | Field                           |
|--------|------|---------------------------------|
| 0x00   | 64   | File info (text description)    |
| 0x40   | 4    | Magic (0xbeda107f)              |
| 0x44   | 4    | Version (0x00010001)            |
| 0x48   | 4    | Header size                     |
| 0x4C   | 4    | Image type (1=dynamic, 2=fixed) |
| 0x50   | 4    | Image flags                     |
| 0x54   | 256  | Description                     |
| 0x154  | 4    | Block map offset                |
| 0x158  | 4    | Data offset                     |
| 0x170  | 8    | Disk size                       |
| 0x178  | 4    | Block size                      |
| 0x17C  | 4    | Block extra data                |
| 0x180  | 4    | Blocks in image                 |
| 0x184  | 4    | Blocks allocated                |

## Image Types

- **Dynamic**: Grows as data is written, sparse
- **Fixed**: Pre-allocated to full size
- **Differencing**: Child image referencing parent (for snapshots)

## Detection

Little-endian magic `0xbeda107f` at offset 0x40 (64 bytes in, after the text
header).

## Tools

```sh
# Create dynamic VDI
VBoxManage createmedium disk --filename disk.vdi --size 102400

# Convert VDI to raw
VBoxManage clonemedium disk.vdi disk.img --format RAW

# Compact VDI (reclaim space)
VBoxManage modifymedium disk.vdi --compact
```

## QEMU Support

QEMU can read and write VDI images directly:

```sh
qemu-system-x86_64 -drive file=disk.vdi,format=vdi
```

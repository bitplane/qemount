---
title: VHD
created: 2003
related:
  - disk/vhdx
  - disk/vmdk
  - disk/vdi
detect:
  any:
    - offset: 0
      type: string
      length: 8
      value: "conectix"
      name: "VHD (fixed)"
    - offset: -512
      type: string
      length: 8
      value: "conectix"
      name: "VHD (dynamic footer)"
---

# Virtual Hard Disk (VHD)

VHD is Microsoft's virtual disk format, originally developed by Connectix for
Virtual PC and acquired by Microsoft in 2003. It's used by Hyper-V, Virtual PC,
and Azure.

## Characteristics

- Fixed, dynamic, or differencing types
- Maximum size: 2 TB (2040 GB actual)
- 512-byte sectors
- Footer at end of file (not header at start)
- No compression or encryption
- Azure compatible

## Types

- **Fixed**: Pre-allocated, footer at end
- **Dynamic**: Sparse, copy of footer at start AND end
- **Differencing**: Child disk with parent reference

## Structure

- Footer (512 bytes) at end of file
- For dynamic: copy of footer at offset 0, then dynamic header
- Block Allocation Table (BAT)
- Data blocks with sector bitmap

## Footer Fields

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 8 | Cookie ("conectix") |
| 0x08 | 4 | Features |
| 0x0C | 4 | Version |
| 0x10 | 8 | Data offset |
| 0x18 | 4 | Timestamp |
| 0x1C | 4 | Creator app |
| 0x20 | 4 | Creator version |
| 0x24 | 4 | Creator host OS |
| 0x28 | 8 | Original size |
| 0x30 | 8 | Current size |
| 0x38 | 4 | Disk geometry |
| 0x3C | 4 | Disk type |
| 0x40 | 4 | Checksum |
| 0x44 | 16 | Unique ID (UUID) |
| 0x54 | 1 | Saved state |

## Detection

The signature "conectix" appears:
- At offset 0 for dynamic/differencing (copy of footer)
- At offset -512 (512 bytes from end) for all types

Note: Detecting VHD requires checking the end of the file, which is unusual.

## Tools

```sh
# Create VHD
qemu-img create -f vpc disk.vhd 100G

# Convert to VHD
qemu-img convert -f qcow2 -O vpc disk.qcow2 disk.vhd

# Hyper-V PowerShell
New-VHD -Path disk.vhd -SizeBytes 100GB -Dynamic
```

## QEMU Notes

QEMU uses format name `vpc` for VHD files:

```sh
qemu-system-x86_64 -drive file=disk.vhd,format=vpc
```

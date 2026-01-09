---
title: VHDX
created: 2012
related:
  - disk/vhd
  - disk/vmdk
detect:
  - offset: 0
    type: string
    length: 8
    value: "vhdxfile"
    name: "VHDX"
---

# Hyper-V Virtual Hard Disk v2 (VHDX)

VHDX is the successor to VHD, introduced with Windows Server 2012 and Hyper-V
3.0. It addresses the limitations of VHD and adds modern features.

## Characteristics

- Maximum size: 64 TB
- 4 KB logical sector support (for 4Kn drives)
- Large block sizes (up to 256 MB)
- Built-in corruption protection (log-based)
- Metadata resilience
- Online resizing
- No compression or encryption (use BitLocker)

## Improvements Over VHD

| Feature | VHD | VHDX |
|---------|-----|------|
| Max size | 2 TB | 64 TB |
| Block size | 2 MB | Up to 256 MB |
| Sector size | 512 bytes | 512 or 4096 |
| Corruption protection | None | Journaling |
| Custom metadata | No | Yes |

## Structure

- File type identifier at offset 0 ("vhdxfile")
- Two headers (primary and secondary) for resilience
- Region table describing layout
- Metadata region
- Block Allocation Table (BAT)
- Data blocks

## Header

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 8 | Signature ("vhdxfile") |
| 0x08 | 504 | Creator (UTF-16) |

## Detection

String "vhdxfile" at offset 0, unlike VHD which has its signature at the end.

## Tools

```sh
# QEMU
qemu-img create -f vhdx disk.vhdx 100G
qemu-img convert -f qcow2 -O vhdx disk.qcow2 disk.vhdx

# Hyper-V PowerShell
New-VHD -Path disk.vhdx -SizeBytes 100GB -Dynamic
Convert-VHD -Path disk.vhd -DestinationPath disk.vhdx
```

## QEMU Support

Full read-write support:

```sh
qemu-system-x86_64 -drive file=disk.vhdx,format=vhdx
```

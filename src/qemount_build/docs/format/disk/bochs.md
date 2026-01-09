---
title: Bochs
created: 1994
related:
  - format/disk/raw
  - format/disk/qcow2
detect:
  - offset: 0
    type: string
    length: 21
    value: "Bochs Virtual HD Image"
    name: "Bochs"
---

# Bochs Disk Image

Bochs is an x86 emulator that predates QEMU. Its disk image format is simple
and designed for the emulator's needs.

## Characteristics

- Simple growing disk format
- Redolog for undo functionality
- CHS geometry stored in header
- Used primarily by Bochs emulator
- Limited practical use today

## Structure

- Text signature at offset 0
- Version and geometry information
- Sparse block allocation
- Optional redolog (undo) file

## Header Fields

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 32 | Signature ("Bochs Virtual HD Image") |
| 0x20 | 16 | Version string |
| 0x30 | 4 | Header size |
| 0x34 | 4 | Version |
| 0x38 | 8 | Disk size (sectors) |

## Detection

String "Bochs Virtual HD Image" at offset 0.

## QEMU Support

QEMU can read Bochs images:

```sh
qemu-system-x86_64 -drive file=disk.img,format=bochs
```

## Bochs Tools

```sh
# Create Bochs image (using Bochs' bximage)
bximage -mode=create -hd=100M -imgmode=growing disk.img
```

## Modern Use

Bochs images are rarely created new today. QEMU's support exists mainly for
compatibility with legacy images from the Bochs era.

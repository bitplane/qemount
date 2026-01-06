---
title: Disk Images
type: category
path: disk
---

# Disk Images

* =¿ container formats for virtual disk data

Disk images are files that contain the contents of a disk drive, either as raw
bytes or in a structured format that adds features like compression, encryption,
or snapshots. Virtual machines use these to simulate hard drives.

## Raw vs Structured

A raw disk image is just the bytes as they would appear on a physical disk -
simple but large. Structured formats add a header and organize the data to
enable features like:

- **Sparse allocation** - only store non-zero regions
- **Snapshots** - save and restore disk state
- **Compression** - reduce file size
- **Encryption** - protect data at rest

## Format Wars

Each hypervisor created its own format: VMware has VMDK, VirtualBox has VDI,
Microsoft has VHD/VHDX, and QEMU has QCOW2. Most can be converted between
formats, and QEMU can read most of them directly.

## Detection

Unlike filesystems which are detected by their content, disk image formats are
detected by their container headers. The actual filesystem inside is a separate
detection step after opening the disk image.

---
title: NetBSD 10.0 Boot Image
requires:
  - bin/qemu/netbsd-${ARCH}/10.0/kernel/netbsd.gdb
  - bin/qemu/netbsd-${ARCH}/10.0/rootfs/ramdisk.fs
provides:
  - bin/qemu/netbsd-${ARCH}/10.0/boot/boot.img
  - bin/qemu/netbsd-${ARCH}/10.0/boot/netbsd
support:
  # filesystems
  - format/fs/ext2
  - format/fs/fat12
  - format/fs/fat16
  - format/fs/fat32
  - format/fs/iso9660
  - format/fs/highsierra
  - format/fs/ufs1
  - format/fs/ufs2
  - format/fs/lfs
  - format/fs/efs
  - format/fs/amiga-ffs
  - format/fs/amiga-ofs
  - format/fs/filecore
  # partition tables
  - format/pt/mbr
  - format/pt/gpt
  - format/pt/bsd-disklabel
  - format/pt/apm
  - format/pt/amiga-rdb
  - format/pt/atari
  # transports
  - transport/9p
  - transport/sh
---

# NetBSD 10.0 Boot Image

Bootable disk image with kernel + embedded ramdisk.

## Architecture

- Boot disk with embedded ramdisk (md0)
- Kernel: GENERIC + QEMOUNT customizations
- Root filesystem: FFS v1 on memory disk
- Console: Serial (com0)

## Kernel-Only Support

These filesystems have kernel support but mount helpers need dynamic libraries:

- HFS/HFS+ - Read-only
- UDF - DVD/Blu-ray
- V7FS - Historical

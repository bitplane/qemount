---
title: NetBSD 10.0 Boot Image
requires:
  - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/kernel/netbsd.gdb
  - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/appliance/rootfs/ramdisk.fs
output_platforms:
  x86_64-netbsd:
    provides:
      - bin/qemu/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot/boot.img
      - bin/qemu/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot/netbsd
  aarch64-netbsd:
    provides:
      - bin/qemu/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot/netbsd
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
  - format/pt/disklabel
  - format/pt/apm
  - format/pt/rdb
  - format/pt/atari
  # transports
  - transport/9p
  - transport/sh
---

# NetBSD 10.0 Boot Image

Bootable kernel with an embedded ramdisk. The amd64 variant also includes a
BIOS boot disk; the evbarm variant is loaded directly by QEMU.

## Architecture

- Kernel with embedded ramdisk (md0)
- Kernel: GENERIC + MOUNTIN customizations
- Root filesystem: FFS v1 on memory disk
- Console: architecture-native serial console

## Kernel-Only Support

These filesystems have kernel support but mount helpers need dynamic libraries:

- HFS/HFS+ - Read-only
- UDF - DVD/Blu-ray
- V7FS - Historical

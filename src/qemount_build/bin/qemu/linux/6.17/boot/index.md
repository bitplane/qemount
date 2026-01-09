---
title: Linux 6.17 Boot
requires:
  - bin/qemu/linux-${ARCH}/6.17/kernel
  - bin/qemu/linux-${ARCH}/rootfs/rootfs.img
provides:
  - bin/qemu/linux-${ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${ARCH}/6.17/boot/rootfs.img
support:
  # filesystems
  - format/fs/ext2
  - format/fs/ext3
  - format/fs/ext4
  - format/fs/cramfs
  - format/fs/squashfs
  - format/fs/minix
  - format/fs/fat12
  - format/fs/fat16
  - format/fs/fat32
  - format/fs/exfat
  - format/fs/sco-bfs
  - format/fs/iso9660
  - format/fs/highsierra
  - format/fs/hfsplus
  - format/fs/hfs
  - format/fs/vxfs
  - format/fs/sysv
  - format/fs/v7
  - format/fs/hpfs
  - format/fs/ntfs
  - format/fs/ufs1
  - format/fs/ufs2
  - format/fs/efs
  - format/fs/amiga-ffs
  - format/fs/amiga-ofs
  - format/fs/romfs
  - format/fs/qnx4
  - format/fs/qnx6
  - format/fs/adfs
  - format/fs/udf
  - format/fs/omfs
  - format/fs/jfs
  - format/fs/xfs
  - format/fs/nilfs2
  - format/fs/beos-bfs
  - format/fs/gfs2
  - format/fs/f2fs
  - format/fs/bcachefs
  - format/fs/erofs
  - format/fs/btrfs
  - format/fs/jffs2
  - format/fs/ubifs
  # partition tables
  - format/pt/mbr
  - format/pt/gpt
  - format/pt/bsd-disklabel
  - format/pt/apm
  - format/pt/amiga-rdb
  - format/pt/atari
  - format/pt/sun
  - format/pt/sgi
  - format/pt/ldm
  - format/pt/minix
  - format/pt/ubi
  - format/pt/acorn
  - format/pt/aix
  - format/pt/ultrix
  - format/pt/sysv68
  - format/pt/karma
  - format/pt/osf
  - format/pt/hpux
  - format/pt/qnx4
  - format/pt/plan9
  - format/pt/cpm
  # transports
  - transport/9p
  - transport/sh
---

# Linux 6.17 Boot

Bootable Linux 6.17 guest. QEMU loads kernel and rootfs (initrd) separately.
Supports modern filesystems including bcachefs, exFAT, F2FS, and EROFS.

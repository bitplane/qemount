---
title: Linux 2.6 Boot
requires:
  - bin/qemu/${ARCH}-linux/2.6/kernel
  - bin/qemu/${ARCH}-linux/rootfs/rootfs.img
provides:
  - bin/qemu/${ARCH}-linux/2.6/boot/kernel
  - bin/qemu/${ARCH}-linux/2.6/boot/rootfs.img
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
  - format/fs/adfs
  - format/fs/udf
  - format/fs/omfs
  - format/fs/jfs
  - format/fs/xfs
  - format/fs/nilfs2
  - format/fs/beos-bfs
  - format/fs/gfs2
  - format/fs/ocfs2
  - format/fs/btrfs
  - format/fs/reiserfs
  - format/fs/jffs2
  # partition tables
  - format/pt/mbr
  - format/pt/gpt
  - format/pt/disklabel
  - format/pt/apm
  - format/pt/rdb
  - format/pt/atari
  - format/pt/sun
  - format/pt/sgi
  - format/pt/minix
  - format/pt/ubi
  - format/pt/acorn
  - format/pt/aix
  - format/pt/disklabel/ultrix
  - format/pt/sysv68
  - format/pt/disklabel/osf
  - format/pt/hpux
  - format/pt/qnx4
  - format/pt/plan9
  - format/pt/cpm
  # transports
  - transport/9p
  - transport/sh
---

# Linux 2.6 Boot

Bootable Linux 2.6 guest. QEMU loads kernel and rootfs (initrd) separately.

## Known Issues

- `fs/sysv`: Symlink creation crashes (NULL pointer in sysv_symlink).
  Write support is broken. TODO: mark as read-only.
- `fs/v7`: May have compatibility issues
- `fs/ntfs`: Read-only via old ntfs driver (not ntfs3)

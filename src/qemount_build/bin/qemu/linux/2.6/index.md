---
title: Linux 2.6 Guest
env:
  BUILDER: builder/compiler/linux/2:${HOST_ARCH}
requires:
  - docker:${BUILDER}
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
  - format/pt/bsd-disklabel
  - format/pt/apm
  - format/pt/amiga-rdb
  - format/pt/atari
  - format/pt/sun
  - format/pt/sgi
  - format/pt/minix
  - format/pt/ubi
  - format/pt/acorn
  - format/pt/aix
  - format/pt/ultrix
  - format/pt/sysv68
  - format/pt/osf
  - format/pt/hpux
  - format/pt/qnx4
  - format/pt/plan9
  - format/pt/cpm
  # transports
  - transport/9p
  - transport/sh
---

# Linux 2.6 Guest

Linux 2.6.39 kernel with busybox. This older kernel supports legacy filesystems
that were removed from modern Linux. Only supports x86/x86_64.

## Known Issues

- `fs/sysv`: Symlink creation crashes (NULL pointer in sysv_symlink)
- `fs/v7`: May have compatibility issues
- `fs/ntfs`: Read-only via old ntfs driver (not ntfs3)

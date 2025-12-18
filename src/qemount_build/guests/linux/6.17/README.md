---
type: guest
os: linux
support:
  # filesystems
  - fs/ext2
  - fs/ext3
  - fs/ext4
  - fs/cramfs
  - fs/squashfs
  - fs/minix
  - fs/fat12
  - fs/fat16
  - fs/fat32
  - fs/exfat
  - fs/sco-bfs
  - fs/iso9660
  - fs/highsierra
  - fs/hfsplus
  - fs/hfs
  - fs/vxfs
  - fs/sysv
  - fs/v7
  - fs/hpfs
  - fs/ntfs
  - fs/ufs1
  - fs/ufs2
  - fs/efs
  - fs/amiga-ffs
  - fs/amiga-ofs
  - fs/romfs
  - fs/qnx4
  - fs/qnx6
  - fs/adfs
  - fs/udf
  - fs/omfs
  - fs/jfs
  - fs/xfs
  - fs/nilfs2
  - fs/beos-bfs
  - fs/gfs2
  - fs/f2fs
  - fs/bcachefs
  - fs/erofs
  - fs/btrfs
  - fs/jffs2
  - fs/ubifs
  # partition tables
  - pt/mbr
  - pt/gpt
  - pt/bsd-disklabel
  - pt/apm
  - pt/amiga-rdb
  - pt/atari
  - pt/sun
  - pt/sgi
  - pt/ldm
  - pt/minix
  - pt/ubi
  - pt/acorn
  - pt/aix
  - pt/ultrix
  - pt/sysv68
  - pt/karma
  - pt/osf
  - pt/hpux
  - pt/qnx4
  - pt/plan9
  - pt/cpm
  # transports
  - transport/9p
  - transport/sh
---

# Linux 6.17 Guest

Linux kernel with busybox. Can mount any filesystems that are built in, listed
in the front-matter above.

## Modes

* `9p`
* `sh`


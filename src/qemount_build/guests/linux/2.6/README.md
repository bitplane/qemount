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
  - fs/adfs
  - fs/udf
  - fs/omfs
  - fs/jfs
  - fs/xfs
  - fs/nilfs2
  - fs/beos-bfs
  - fs/gfs2
  - fs/ocfs2
  - fs/btrfs
  - fs/reiserfs
  - fs/jffs2
  # partition tables
  - pt/mbr
  - pt/gpt
  - pt/bsd-disklabel
  - pt/apm
  - pt/amiga-rdb
  - pt/atari
  - pt/sun
  - pt/sgi
  - pt/minix
  - pt/ubi
  - pt/acorn
  - pt/aix
  - pt/ultrix
  - pt/sysv68
  - pt/osf
  - pt/hpux
  - pt/qnx4
  - pt/plan9
  - pt/cpm
  # transports
  - transport/9p
  - transport/sh
---

# Linux 2.6 Guest

Linux 2.6.39 kernel with busybox. This older kernel supports legacy filesystems
that were removed from modern Linux, including ReiserFS and OCFS2.

## Modes

* `9p`
* `sh`

## Legacy Filesystem Support

This guest is useful for accessing:
- ReiserFS (removed in Linux 6.13)
- OCFS2 (cluster filesystem)
- Older filesystem variants

## Known Issues

- `fs/sysv`: Symlink creation crashes (NULL pointer in sysv_symlink)
- `fs/v7`: May have compatibility issues
- `fs/ntfs`: Read-only via old ntfs driver (not ntfs3)

## Not Supported

Filesystems added after 2.6.39:
- exFAT (added 5.4)
- F2FS (added 3.8)
- bcachefs (added 6.7)
- EROFS (added 5.4)
- QNX6 (added 4.3)
- UBIFS (added 2.6.27, may work)

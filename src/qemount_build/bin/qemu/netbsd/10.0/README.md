---
os: netbsd
support:
  # filesystems
  - fs/ext2
  - fs/fat12
  - fs/fat16
  - fs/fat32
  - fs/iso9660
  - fs/highsierra
  - fs/ufs1
  - fs/ufs2
  - fs/lfs
  - fs/efs
  - fs/amiga-ffs
  - fs/amiga-ofs
  - fs/filecore
  # partition tables
  - pt/mbr
  - pt/gpt
  - pt/bsd-disklabel
  - pt/apm
  - pt/amiga-rdb
  - pt/atari
  # transports
  - transport/9p
  - transport/sh
---

# NetBSD 10.0 Guest

NetBSD guest for qemount, providing filesystem mounting capabilities via QEMU.

## Kernel-Only Support (needs dynamic libraries for mount)

These filesystems have kernel support but mount helpers require dynamic
libraries which aren't available in the static rescue environment:

| Filesystem | Description | Notes |
|------------|-------------|-------|
| HFS/HFS+ | Apple Hierarchical Filesystem | Read-only |
| UDF | Universal Disk Format | DVD/Blu-ray |
| V7FS | 7th Edition Unix Filesystem | Historical |
| NFS | Network File System | Would need networking |

## Architecture

- Boot disk with embedded ramdisk (md0)
- Kernel: GENERIC + QEMOUNT customizations
- Root filesystem: FFS v1 on memory disk
- Console: Serial (com0)

## Future Work

- 9P mode for FUSE integration
- Dynamic library support for HFS, UDF, V7FS mount helpers
- Additional architecture support (aarch64)
